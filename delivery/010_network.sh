#!/bin/bash

echo "------------------------------------------------------------------"
echo "Networking: Setting Up"
echo "------------------------------------------------------------------"
cat <<-__EOF__ > /etc/network/interfaces
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

auto lo
iface lo inet loopback

allow-hotplug eth0
iface eth0 inet dhcp

allow-hotplug usb0
iface usb0 inet dhcp
__EOF__

echo "------------------------------------------------------------------"
echo "Networking: Done"
echo "------------------------------------------------------------------"
