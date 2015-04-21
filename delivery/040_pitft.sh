#!/bin/bash

BannerEcho "PiTFT: Installing"
mkdir -p pitft
pushd pitft

BannerEcho "PiTFT: Getting Packages"

GetFile "http://adafruit-download.s3.amazonaws.com" "libraspberrypi-bin-adafruit.deb"
GetFile "http://adafruit-download.s3.amazonaws.com" "libraspberrypi-dev-adafruit.deb"
GetFile "http://adafruit-download.s3.amazonaws.com" "libraspberrypi-doc-adafruit.deb"
GetFile "http://adafruit-download.s3.amazonaws.com" "libraspberrypi0-adafruit.deb"
GetFile "http://adafruit-download.s3.amazonaws.com" "raspberrypi-bootloader-adafruit-112613.deb"


BannerEcho "PiTFT: Setting up New Kernel"
dpkg -i -B *.deb


BannerEcho "PiTFT: Setting up LCD Drivers"

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


BannerEcho "PiTFT: Setting up Touchscreen"

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


BannerEcho "PiTFT: Done"

popd
