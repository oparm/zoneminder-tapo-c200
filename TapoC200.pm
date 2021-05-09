# ==========================================================================
#
# ZoneMinder Tapo C200 IP Control Protocol Module
# $Date: 2021-05-09$, $Revision: 0001$
#
# Copyright 2021 https://github.com/oparm
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# ==========================================================================
#
package ZoneMinder::Control::TapoC200;

use 5.006;
use strict;
use warnings;

use IO::Socket::SSL;
use Time::HiRes qw(usleep);
use Data::Dumper;
use LWP::UserAgent;
use JSON::Parse 'parse_json';
use Digest::MD5 qw(md5_hex);
use JSON;

require ZoneMinder::Base;
require ZoneMinder::Control;

our @ISA = qw(ZoneMinder::Control);
 
our $VERSION = $ZoneMinder::Base::VERSION;
 
# ==========================================================================
#
# TAPO C200 IP Control Protocol
#
# ==========================================================================

my $tapo_c200_debug = 0;
my $step = 15;

use ZoneMinder::Logger qw(:all);
use ZoneMinder::Config qw(:all);
use ZoneMinder::Database qw(zmDbConnect);

my ($user, $pass, $host, $port, $retry_command);

sub open
{
    my $self = shift;
    $self->loadMonitor();

    if ($self->{Monitor}{ControlAddress} =~ /^([^:]+):([^@]+)@(.+)/) {
        $user = $1;
        $pass = $2;
        $host = $3;
    } else {
        Error("Control Address URL must be entered as 'admin:admin_password\@host:port', exiting");
        Exit(0);
    }

    if ($host =~ /([^:]+):(.+)/) {
        $host = $1;
        $port = $2;
    } else {
        $port = 443;
    }

    $self->{user} = $user;
    $self->{pass} = $pass;
    $self->{BaseURL} = "https://$host:$port";

    # Disable verification of Tapo C200 self-signed certificate
    use LWP::UserAgent;
    $self->{ua} = LWP::UserAgent->new(
        ssl_opts => {
            verify_hostname => 0,
            SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE,
        }
    );

    $self->{ua}->agent("ZoneMinder Control Agent/".ZoneMinder::Base::ZM_VERSION);

    if ($self->{user} ne 'admin') {
        Error("Username should be 'admin' but '$self->{user}' was found");
    }
    
    # Retrieve and store token during opening
    $self->setToken();

    $self->{state} = 'open';
    
    Info("Tapo C200 Controller opened");
}

sub close
{ 
    my $self = shift;

    $self->{user} = undef;
    $self->{pass} = undef;
    $self->{BaseURL} = undef;
    $self->{token} = undef;
    $self->{state} = 'closed';
}

sub printMsg
{
    my $msg = shift;

    if ($tapo_c200_debug == 1) {
        Info($msg);
    } else {
        Debug($msg);
    }
}

sub setToken
{
    my $self = shift;

    my $result = undef;
    my $token = undef;

    my $hashed_password = uc(md5_hex($self->{pass}));

    my $payload = '{"method":"login","params":{"hashed":"true","password":"'.$hashed_password.'","username":"'.$self->{user}.'"}}';

    my $req = HTTP::Request->new(POST => $self->{BaseURL});

    $req->header('content-type' => 'application/json');
    $req->header('Host' => $self->{BaseURL});
    $req->header('content-length' => length($payload));
    $req->header('accept-encoding' => 'gzip, deflate');
    $req->header('requestByApp' => 'true');
    $req->header('connection' => 'close');

    $req->content($payload);

    my $response = $self->{ua}->request($req);

    if ($response->is_success) {

        my $cmd_error_code = decode_json($response->content)->{error_code};

        if ($cmd_error_code == 0) {
            $self->{token} = decode_json($response->content)->{result}->{stok};

            Info("Token retrieved for $self->{BaseURL}");

            return $self->{token};
        } elsif ($cmd_error_code == -40401) {
            Error("Invalid credentials for $self->{BaseURL}, exiting");
            Exit(0);
        }
    } else {
        Error("Could send request to retrieve token for $self->{BaseURL} : $response->status_line()");
        
        return undef;
    }
}

sub sendCmd
{
    my $self = shift;
    my $cmd = shift;

    my $result = undef;
    my $token = undef;

    my $req = HTTP::Request->new(POST => "$self->{BaseURL}/stok=$self->{token}/ds");

    $req->header('content-type' => 'application/json');
    $req->header('Host' => $self->{BaseURL});
    $req->header('content-length' => length($cmd));
    $req->header('accept-encoding' => 'gzip, deflate');
    $req->header('requestByApp' => 'true');
    $req->header('connection' => 'close');

    $req->content($cmd);

    my $response = $self->{ua}->request($req);

    if ($response->is_success) {
        my $cmd_error_code = decode_json($response->content)->{error_code};

        if ($cmd_error_code == 0) {
            printMsg("Command sent successfully to $self->{BaseURL} : $cmd");
        } elsif ($cmd_error_code == -40401) {
            printMsg("Token expired for $self->{BaseURL}, retrying : $cmd");

            $self->setToken();
            $self->sendCmd($cmd);
        } else {
            Error("Camera failed to execute command to $self->{BaseURL} : $cmd");
            Error(Dumper($response->content));
        }

        return 1;
    } else {
        Error("Could not send command to $self->{BaseURL} : $response->status_line()");
    }
}

sub moveConUp
{
    my $self = shift;
    printMsg("Move Up");

    $self->sendCmd('{"method":"do","motor":{"move":{"x_coord":"0","y_coord":"'.$step.'"}}}');
}

sub moveConDown
{
    my $self = shift;
    printMsg("Move Down");

    $self->sendCmd('{"method":"do","motor":{"move":{"x_coord":"0","y_coord":"-'.$step.'"}}}');
}

sub moveConLeft
{
    my $self = shift;
    printMsg("Move Left");

    $self->sendCmd('{"method":"do","motor":{"move":{"x_coord":"-'.$step.'","y_coord":"0"}}}');
}

sub moveConRight
{
    my $self = shift;
    printMsg("Move Right");

    $self->sendCmd('{"method":"do","motor":{"move":{"x_coord":"'.$step.'","y_coord":"0"}}}');
}

sub moveConUpRight
{
    my $self = shift;
    printMsg("Move Diagonally Up Right");

    $self->sendCmd('{"method":"do","motor":{"move":{"x_coord":"'.$step.'","y_coord":"'.$step.'"}}}');
}

sub moveConDownRight
{
    my $self = shift;
    printMsg("Move Diagonally Down Right");

    $self->sendCmd('{"method":"do","motor":{"move":{"x_coord":"'.$step.'","y_coord":"-'.$step.'"}}}');
}

sub moveConUpLeft
{
    my $self = shift;
    printMsg("Move Diagonally Up Left");

    $self->sendCmd('{"method":"do","motor":{"move":{"x_coord":"-'.$step.'","y_coord":"'.$step.'"}}}');
}

sub moveConDownLeft
{
    my $self = shift;
    printMsg("Move Diagonally Down Left");

    $self->sendCmd('{"method":"do","motor":{"move":{"x_coord":"-'.$step.'","y_coord":"-'.$step.'"}}}');
}

sub moveStop
{
    my $self = shift;
    printMsg("Move Stop");

    $self->sendCmd('{"method":"do","motor":{"stop":"null"}}');
}

sub presetGoto
{
    my $self = shift;
    my $params = shift;
    my $preset = $self->getParam($params, 'preset');
    printMsg("Go To Preset ".$preset);
    
    $self->sendCmd('{"method":"do","preset":{"goto_preset": {"id": "'.$preset.'"}}}');
}

sub presetSet
{
    my $self = shift;
    my $params = shift;
    my $preset = $self->getParam($params, 'preset');

    # Tapo C200 supports up to 8 presets
    if ($preset < 1 || $preset > 8) {
        Error("Invalid preset, it must be between 1 and 8', exiting");
        Exit(0);
    }

    my $dbh = zmDbConnect(1);
    my $sql = 'SELECT * FROM ControlPresets WHERE MonitorId = ? AND Preset = ?';
    my $sth = $dbh->prepare($sql);
    my $res = $sth->execute($self->{Monitor}->{Id}, $preset);
    my $ref = ($sth->fetchrow_hashref());
    my $label = $ref->{'Label'};

    printMsg("Set Preset '$preset' with label \"$label\"");

    # Remove preset, so we can update with the new data
    $self->sendCmd('{"method":"do","preset":{"remove_preset":{"id":['.$preset.']}}}');

    # Create/update preset
    $self->sendCmd('{"method":"do","preset":{"set_preset":{"id":"'.$preset.'","name":"'.$label.'","save_ptz":"1"}}}');
}

sub reset
{
    my $self = shift;

    if ($tapo_c200_debug == 1) {
        printMsg("Reloading controller for $self->{BaseURL}, exiting");
        Exit(0);
    } else {
        printMsg("Resetting position for $self->{BaseURL}");
        $self->sendCmd('{"method":"do","motor":{"manual_cali":"null"}}');
    }
}

sub reboot
{
    my $self = shift;
    printMsg("Rebooting $self->{BaseURL}");
    
    $self->sendCmd('{"method":"do","system":{"reboot":"null"}}');
}

sub wake
{
    my $self = shift;
    printMsg("Disabling Lens Mask for $self->{BaseURL}");
    
    $self->sendCmd('{"method":"set","lens_mask":{"lens_mask_info":{"enabled":"off"}}}');
}
 
sub sleep
{
    my $self = shift;
    printMsg("Enabling Lens Mask for $self->{BaseURL}");
    
    $self->sendCmd('{"method":"set","lens_mask":{"lens_mask_info":{"enabled":"on"}}}');
}

1;
