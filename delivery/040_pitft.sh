#!/bin/bash

echo "------------------------------------------------------------------"
echo "PiTFT: Install starting"
echo "------------------------------------------------------------------"
mkdir -p pitft
pushd pitft

echo "------------------------------------------------------------------"
echo "PiTFT: Getting packages"
echo "------------------------------------------------------------------"

GetFile "http://adafruit-download.s3.amazonaws.com" "libraspberrypi-bin-adafruit.deb"
GetFile "http://adafruit-download.s3.amazonaws.com" "libraspberrypi-dev-adafruit.deb"
GetFile "http://adafruit-download.s3.amazonaws.com" "libraspberrypi-doc-adafruit.deb"
GetFile "http://adafruit-download.s3.amazonaws.com" "libraspberrypi0-adafruit.deb"
GetFile "http://adafruit-download.s3.amazonaws.com" "raspberrypi-bootloader-adafruit-112613.deb"


echo "------------------------------------------------------------------"
echo "PiTFT: Setting up new Kernel"
echo "------------------------------------------------------------------"
dpkg -i -B *.deb


echo "------------------------------------------------------------------"
echo "PiTFT: Setting up LCD Drivers"
echo "------------------------------------------------------------------"

echo "spi-bcm2708
fbtft_device
rpi_power_switch
" >> /etc/modules

mkdir -p /etc/modprobe.d
echo "options fbtft_device name=adafruitts rotate=90 frequency=32000000
options rpi_power_switch gpio_pin=23 mode=0
" >> /etc/modprobe.d/adafruit.conf

mkdir -p /etc/X11/xorg.conf.d
#echo 'Section "InputClass"
#        Identifier      "calibration"
#        MatchProduct    "stmpe-ts"
#        Option  "Calibration"   "3800 200 200 3800"
#        Option  "SwapAxes"      "0"
#EndSection
#' >> /etc/X11/xorg.conf.d/99-calibration.conf

#mkdir -p /home/pi
#echo "export FRAMEBUFFER=/dev/fb1
#startx &
#" >> /home/pi/.profile


echo "------------------------------------------------------------------"
echo "PiTFT: Setting up Touchscreen"
echo "------------------------------------------------------------------"

AptInstall evtest tslib libts-bin

mkdir -p /etc/udev/rules.d/
echo 'SUBSYSTEM=="input", ATTRS{name}=="stmpe-ts", ENV{DEVNAME}=="*event*", SYMLINK+="input/touchscreen
' >> /etc/udev/rules.d/95-stmpe.rules

echo 'Section "InputClass"
        Identifier      "calibration"
        MatchProduct    "stmpe-ts"
        Option	"Calibration"   "3736 119 174 3850"
	Option	"SwapAxes"	"1"
EndSection' >> /etc/X11/xorg.conf.d/99-calibration.conf

echo "stmpe_ts
" >> /etc/modules


echo "------------------------------------------------------------------"
echo "PiTFT: Done"
echo "------------------------------------------------------------------"

popd
