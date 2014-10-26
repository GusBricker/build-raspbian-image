#!/bin/sh

echo "------------------------------------------------------------------"
echo "Desktop: Setting Up"
echo "------------------------------------------------------------------"
OLD_DEBIAN_FRONTEND=${DEBIAN_FRONTEND}
export DEBIAN_FRONTEND=noninteractive
apt-get -y -q install lightdm
apt-get -y install xserver-xorg-video-fbdev
apt-get -y install x11-xserver-utils
apt-get -y install xvkbd
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
