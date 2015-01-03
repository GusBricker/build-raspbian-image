#!/bin/bash

echo "------------------------------------------------------------------"
echo "X11: Setting Up"
echo "------------------------------------------------------------------"
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

echo "------------------------------------------------------------------"
echo "X11: Done"
echo "------------------------------------------------------------------"
