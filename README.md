# ZoneMinder Tapo C200 camera control script

A [ZoneMinder](https://zoneminder.com/) PTZ control script for the Tapo C200 camera.

## Features
- Pan
- Tilt
- Zoom through ZoneMinder
- Sleep : Lens Mask On
- Wake : Lens Mask Off
- Up to 8 presets
- Reset (camera recalibrates and returns to its default position)
- Reboot

## Demos

### Pan/Tilt

https://user-images.githubusercontent.com/83918778/117584495-a708e000-b10d-11eb-98a3-c0f087e0ff37.mp4

### Presets
https://user-images.githubusercontent.com/83918778/117584497-a8d2a380-b10d-11eb-9d0c-7d544fdc88d6.mp4

### Lens Mask
https://user-images.githubusercontent.com/83918778/117584499-a96b3a00-b10d-11eb-9521-35f39ba2f2d3.mp4

## Reset & Reboot explanations

### Reset

The camera will recalibrate by panning and tilting itself.

Or, if you enabled the script debugging, it will reload the script.

### Reboot

It does indeed reboot the camera...

## Install the script

On your system, copy the file named **TapoC200.pm** to **/usr/share/perl5/ZoneMinder/Control/**.

Make sure it has the same permissions as the existing control scripts in that directory :

<pre>
root@security:/usr/share/perl5/ZoneMinder/Control# ls -alh
total 584K
drwxr-xr-x 2 root root 4.0K May  9 20:08 .
drwxr-xr-x 5 root root 4.0K May  6 22:27 ..
-rw-r--r-- 1 root root  12K Apr 20 01:34 3S.pm
-rw-r--r-- 1 root root  14K Apr 20 01:34 Amcrest_HTTP.pm
-rw-r--r-- 1 root root  12K Apr 20 01:34 AxisV2.pm
-rw-r--r-- 1 root root  18K Apr 20 01:34 Dahua.pm
-rw-r--r-- 1 root root 4.8K Apr 20 01:34 DCS3415.pm
-rw-r--r-- 1 root root 7.3K Apr 20 01:34 DCS5020L.pm
-rw-r--r-- 1 root root  13K Apr 20 01:34 DericamP2.pm
-rw-r--r-- 1 root root  23K Apr 20 01:34 FI8608W_Y2k.pm
-rw-r--r-- 1 root root  26K Apr 20 01:34 FI8620_Y2k.pm
-rw-r--r-- 1 root root 6.2K Apr 20 01:34 FI8908W.pm
-rw-r--r-- 1 root root 7.6K Apr 20 01:34 FI8918W.pm
-rw-r--r-- 1 root root  22K Apr 20 01:34 FI9821W_Y2k.pm
-rw-r--r-- 1 root root  23K Apr 20 01:34 FI9831W.pm
-rw-r--r-- 1 root root 8.2K Apr 20 01:34 Floureon.pm
-rw-r--r-- 1 root root 9.5K Apr 20 01:34 FOSCAMR2C.pm
-rw-r--r-- 1 root root  12K Apr 20 01:34 HikVision.pm
-rw-r--r-- 1 root root 6.9K Apr 20 01:34 IPCAMIOS.pm
-rw-r--r-- 1 root root 8.1K Apr 20 01:34 IPCC7210W.pm
-rw-r--r-- 1 root root 6.9K Apr 20 01:34 Keekoon.pm
-rw-r--r-- 1 root root 9.6K Apr 20 01:34 LoftekSentinel.pm
-rw-r--r-- 1 root root  11K Apr 20 01:34 M8640.pm
-rw-r--r-- 1 root root 7.2K Apr 20 01:34 MaginonIPC.pm
-rw-r--r-- 1 root root 4.6K Apr 20 01:34 mjpgStreamer.pm
-rw-r--r-- 1 root root 4.6K Apr 20 01:34 Ncs370.pm
-rw-r--r-- 1 root root  25K Apr 20 01:34 Netcat.pm
-rw-r--r-- 1 root root 8.7K Apr 20 01:34 onvif.pm
-rw-r--r-- 1 root root 6.6K Apr 20 01:34 PanasonicIP.pm
-rw-r--r-- 1 root root  18K Apr 20 01:34 PelcoD.pm
-rw-r--r-- 1 root root  19K Apr 20 01:34 PelcoP.pm
-rw-r--r-- 1 root root 9.7K Apr 20 01:34 PSIA.pm
-rw-r--r-- 1 root root  39K Apr 20 01:34 Reolink.pm
-rw-r--r-- 1 root root 6.3K Apr 20 01:34 SkyIPCam7xx.pm
-rw-r--r-- 1 root root 8.2K Apr 20 01:34 Sony.pm
-rw-r--r-- 1 root root 7.7K Apr 20 01:34 SPP1802SWPTZ.pm
<b>-rw-r--r-- 1 root root 9.6K May  9 20:08 TapoC200.pm</b>
-rw-r--r-- 1 root root 5.2K Apr 20 01:34 Toshiba_IK_WB11A.pm
-rw-r--r-- 1 root root  12K Apr 20 01:34 Trendnet.pm
-rw-r--r-- 1 root root  20K Apr 20 01:34 Visca.pm
-rw-r--r-- 1 root root 4.6K Apr 20 01:34 Vivotek_ePTZ.pm
-rw-r--r-- 1 root root 8.9K Apr 20 01:34 WanscamHW0025.pm
-rw-r--r-- 1 root root  13K Apr 20 01:34 Wanscam.pm
</pre>

## Camera configuration in ZoneMinder

Use the same configuration when testing, unless stated otherwise.

### Monitor source tab

**Source Path** is the RTSP path used to display the stream inside ZoneMinder, it has nothing to do with the control script.
Inside the mobile application, create an account linked to the camera and use those credentials in the "Source Path".

Change user, password and IP. Leave the port to 554 and /stream1.

![tapoc200-monitor-source-tab](https://user-images.githubusercontent.com/83918778/117584518-c6077200-b10d-11eb-86fa-7aba61aa6eca.jpg)

### Monitor control tab

![tapoc200-monitor-control-tab](https://user-images.githubusercontent.com/83918778/117584528-cbfd5300-b10d-11eb-85be-8ce2536e8d0b.jpg)

**Control Address** is the HTTPS path used to control the camera inside ZoneMinder.

Change admin_password to the password you created when you installed the mobile application (the password linked to your email address).

Change the IP address. **Leave the username to "admin"**, and the port to 443.

**Control Type** : Click on "Edit" from the previous screenshot, and click on the link named "Tapo C200" inside the list showing up.
If you don't see "Tapo C200" in the list then the script is not correctly installed.

### Control capabilites tab

![tapoc200-monitor-control-capabilities-tab](https://user-images.githubusercontent.com/83918778/117584541-d881ab80-b10d-11eb-8225-550ae722836e.jpg)

### Control capability main tab

Use the same settings as :

![tapoc200-monitor-control-capability-main-tab](https://user-images.githubusercontent.com/83918778/117584549-e2a3aa00-b10d-11eb-9db6-cb4095afcc2d.jpg)

### Control capability move tab

Use the same settings as :

![tapoc200-monitor-control-capability-move-tab](https://user-images.githubusercontent.com/83918778/117584552-e8998b00-b10d-11eb-9c2c-36503ea496d6.jpg)

### Control capability pan tab

Use the same settings as :

![tapoc200-monitor-control-capability-pan-tab](https://user-images.githubusercontent.com/83918778/117584555-edf6d580-b10d-11eb-9d69-c60ca8c8f786.jpg)

### Control capability tilt tab

Use the same settings as :

![tapoc200-monitor-control-capability-tilt-tab](https://user-images.githubusercontent.com/83918778/117584561-f3542000-b10d-11eb-98ff-38b53cc5a98c.jpg)

### Control capability presets tab

Use the same settings as :

![tapoc200-monitor-control-capability-presets-tab](https://user-images.githubusercontent.com/83918778/117584565-f7803d80-b10d-11eb-8752-9f24c744ce74.jpg)

## Check that the script is running

You can see the script's output in two ways :

1. Inside ZoneMinder in the by clicking on "Log" in the main menu
2. Or directly inside **/var/log/zm/zmcontrol_1.log**, here is how it should looks like :

```
...
05/09/2021 20:08:43.224080 zmcontrol_1[18057].INF [main:134] [Starting control server 1/TapoC200]
05/09/2021 20:08:43.264927 zmcontrol_1[18057].INF [main:141] [Control server 1/TapoC200 starting at 21/05/09 20:08:43]
05/09/2021 20:08:43.401039 zmcontrol_1[18057].INF [ZoneMinder::Control::TapoC200:165] [Token retrieved for https://192.168.1.1:443]
05/09/2021 20:08:43.406488 zmcontrol_1[18057].INF [ZoneMinder::Control::TapoC200:109] [Tapo C200 Controller opened]
...
```

## How to edit & troubleshoot the script

If you need to troubleshoot more deeply, enable the script debugging :

```
...
my $tapo_c200_debug = 1;
...
```

Reload the script by clicking "Save" in any window shown on the screenshots.

**Now you can reload the script easily by clicking the "Reset" buttons inside ZoneMinder.**

When the variable is set to 1, the "Reset" button in ZoneMinder will reload the script instead of calibrating the camera position.
This allows you to edit the script file and click on "Reset" so that your modifications are taken into account by ZoneMinder.

When you are done set that variable back to 0.

```
...
my $tapo_c200_debug = 0;
...
```

## Pan and tilt stepping

Set this variable to either 5/10/15. Those are the steps used by the mobile application, so they are supposed safe.

```
...
my $step = 15;
...
```

## Useful links and thanks to :

https://research.nccgroup.com/2020/07/31/lights-camera-hacked-an-insight-into-the-world-of-popular-ip-cameras/

https://github.com/likaci/mercury-ipc-control

https://github.com/ttimasdf/mercury-ipc-control

http://blog.xiazhiri.com/Mercury-MIPC251C-4-Reverse.html

https://md.depau.eu/s/r1Ys_oWoP#

https://github.com/JurajNyiri/HomeAssistant-Tapo-Control

https://community.home-assistant.io/t/use-pan-tilt-function-for-tp-link-tapo-c200-from-home-assistant/170143/18

https://www.henrychang.ca/foscam-f9821p-v2-control-zoneminder-script/
