#!/bin/bash

BannerEcho "X11: Setting Up"

AptInstall xserver-xorg-video-fbdev
AptInstall x11-xserver-utils
AptInstall xinit

mkdir -p /usr/share/X11/xorg.conf.d
echo 'Section "Device"  
	Identifier "myfb"
	Driver "fbdev"
	Option "fbdev" "/dev/fb1"
EndSection
' >> /usr/share/X11/xorg.conf.d/99-fbdev.conf 

BannerEcho "X11: Done"
