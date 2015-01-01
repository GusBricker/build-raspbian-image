#!/bin/bash

echo "------------------------------------------------------------------"
echo "Desktop: Setting Up"
echo "------------------------------------------------------------------"
OLD_DEBIAN_FRONTEND=${DEBIAN_FRONTEND}
export DEBIAN_FRONTEND=noninteractive
AptInstall -q lightdm
AptInstall xserver-xorg-video-fbdev
AptInstall x11-xserver-utils
AptInstall xvkbd
export DEBIAN_FRONTEND=${OLD_DEBIAN_FRONTEND}

mkdir -p /usr/share/X11/xorg.conf.d
echo 'Section "Device"  
	Identifier "myfb"
	Driver "fbdev"
	Option "fbdev" "/dev/fb1"
EndSection
' >> /usr/share/X11/xorg.conf.d/99-fbdev.conf 

echo '#!/bin/bash
/usr/bin/xvkbd -display $DISPLAY&
' >> /etc/lightdm/virt-keyb.sh

update-rc.d lightdm enable 2
sed /etc/lightdm/lightdm.conf -i -e "s/^#autologin-user=.*/autologin-user=pi/"
#sed /etc/lightdm/lightdm.conf -i -e "s/^#greeter-setup-script=.*/greeter-setup-script=virt-keyb.sh/"

# Set lightdm to auto login
#/usr/lib/lightdm/lightdm-set-defaults --autologin pi

echo "------------------------------------------------------------------"
echo "Desktop: Done"
echo "------------------------------------------------------------------"
