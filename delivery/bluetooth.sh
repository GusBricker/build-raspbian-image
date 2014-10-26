#!/bin/sh

echo "------------------------------------------------------------------"
echo "Desktop: Setting Up"
echo "------------------------------------------------------------------"
#apt-get -y install bluetooth bluez-utils bluez-compat bridge-utils blueman
apt-get -y install bluetooth bluez python-gobject

echo '#!/bin/sh
bluez-test-adapter discoverable on
sdptool nap
bluez-simple-agent &
echo "$!" > /tmp/bluez-simple-agent.pid
' > /usr/bin/bluez-enter-pairmode.sh
chmod +x /usr/bin/bluez-enter-pairmode.sh

echo '#!/bin/sh
bluez-test-adapter discoverable off
kill -9 $(<"/tmp/bluez-simple-agent.pid")
rm -f /tmp/bluez-simple-agent.pid
' > /usr/bin/bluez-exit-pairmode.sh
chmod +x /usr/bin/bluez-exit-pairmode.sh

echo '#!/bin/sh
bluez-test-device trusted $1 yes
' > /usr/bin/bluez-trustdevice.sh
chmod +x /usr/bin/bluez-trustdevice.sh


echo '#!/usr/bin/python

from __future__ import absolute_import, print_function, unicode_literals

import sys
import time
import dbus
from optparse import OptionParser, make_option
#import bluezutils

bus = dbus.SystemBus()

	manager = dbus.Interface(bus.get_object("org.bluez", "/"),
			"org.bluez.Manager")

	option_list = [
	make_option("-i", "--device", action="store",
			type="string", dest="dev_id"),
	]
parser = OptionParser(option_list=option_list)

(options, args) = parser.parse_args()

	if options.dev_id:
adapter_path = manager.FindAdapter(options.dev_id)
	else:
adapter_path = manager.DefaultAdapter()

	server = dbus.Interface(bus.get_object("org.bluez", adapter_path),
			"org.bluez.NetworkServer")

	service = "nap"

	if (len(args) < 1):
		bridge = "tether"
		else:
		bridge = args[0]

		server.Register(service, bridge)

	print("Server for %s registered for %s" % (service, bridge))

	print("Press CTRL-C to disconnect")

	try:
time.sleep(1000)
	print("Terminating connection")
	except:
	pass

server.Unregister(service)
' > /usr/bin/bluez-test-nap
chmod +x /usr/bin/bluez-test-nap

echo '### BEGIN INIT INFO
# Provides:          nap
# Required-Start:    $remote_fs $all
# Required-Stop:     $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Starts and stops python script
# Description:       Starts and stops python script
### END INIT INFO

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=/usr/bin/bluez-test-nap
NAME=nap
DESC="Bluetooth NAP Script"

test -x $DAEMON || exit 0

. /lib/lsb/init-functions

set -e

case "$1" in
start)
echo -n "Starting $DESC: "
start-stop-daemon --start --quiet --pidfile /var/run/$NAME.pid --background --make-pidfile --exec $DAEMON
echo "$NAME."
;;
stop)
echo -n "Stopping $DESC: "
start-stop-daemon --stop --oknodo --quiet --pidfile /var/run/$NAME.pid
echo "$NAME."
;;
restart)
$0 stop
sleep 1
$0 start
;;
*)
echo "Usage: $0 {start|stop|restart}" >&2
exit 1
;;

esac

exit 0
' >> /etc/init.d/nap
chmod +x /etc/init.d/nap

update-rc.d nap defaults

echo 'allow-hotplug bnep0
iface bnep0 inet static
address 169.254.3.2
netmask 255.255.0.0
' > /etc/networking/interfaces

#echo "class 0x020300;
#lm master;
#discovto 0;
#" > /etc/bluetooth/hcid.conf

#echo "--listen --role NAP -u /etc/bluetooth/pan/dev-up -o /etc/bluetooth/pan/dev-down
#" >> /etc/defaults/bluetooth
echo "------------------------------------------------------------------"
echo "Bluetooth: Done"
echo "------------------------------------------------------------------"
