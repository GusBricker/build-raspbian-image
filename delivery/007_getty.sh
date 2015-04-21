#!/bin/bash

BannerEcho "Getty: Setting Up"

echo "T0:23:respawn:/sbin/getty -L ttyAMA0 115200 vt100" >> /etc/inittab

BannerEcho "Getty: Done"
