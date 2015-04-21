#!/bin/bash

# build your own Raspberry Pi SD card
#
# Modifications by
# Andrius Kairiukstis <andrius@kairiukstis.com>, http://andrius.mobi/
#
# 2013-05-05
#	resulting files will be stored in rpi folder of script
#	during installation, delivery contents folder will be mounted and install.sh script within it will be called
#
# 2013-04-20
#	distro replaced from Debian Wheezy to Raspbian (http://raspbian.org)
#	build environment and resulting files not in /tmp/rpi instead of /root/rpi
#	fixed umount issue
#	keymap selection replaced from German (deadkeys) to the US
#	size of resulting image was increased to 2GB
#
#	Install apt-cacher-ng (apt-get install apt-cacher-ng) and use deb_local_mirror
#	more: https://www.unix-ag.uni-kl.de/~bloch/acng/html/config-servquick.html#config-client
#
#
#
# by Klaus M Pfeiffer, http://blog.kmp.or.at/
#
# 2012-06-24
#	just checking for how partitions are called on the system (thanks to Ricky Birtles and Luke Wilkinson)
#	using http.debian.net as debian mirror,
#	see http://rgeissert.blogspot.co.at/2012/06/introducing-httpdebiannet-debians.html
#	tested successfully in debian squeeze and wheezy VirtualBox
#	added hint for lvm2
#	added debconf-set-selections for kezboard
#	corrected bug in writing to etc/modules
#
# 2012-06-16
#	improoved handling of local debian mirror
#	added hint for dosfstools (thanks to Mike)
#	added vchiq & snd_bcm2835 to /etc/modules (thanks to Tony Jones)
#	take the value fdisk suggests for the boot partition to start (thanks to Mike)
#
# 2012-06-02
#       improoved to directly generate an image file with the help of kpartx
#	added deb_local_mirror for generating images with correct sources.list
#
# 2012-05-27
#	workaround for https://github.com/Hexxeh/rpi-update/issues/4
#	just touching /boot/start.elf before running rpi-update
#
# 2012-05-20
#	back to wheezy, http://bugs.debian.org/672851 solved,
#	http://packages.qa.debian.org/i/ifupdown/news/20120519T163909Z.html
#
# 2012-05-19
#	stage3: remove eth* from /lib/udev/rules.d/75-persistent-net-generator.rules
#	initial

# you need at least
# apt-get install binfmt-support qemu qemu-user-static debootstrap kpartx lvm2 dosfstools

function usage()
{
    cat <<-__EOF__
Usage: build_raspbian_sd_card.sh <options>...
Builds a custom SD card for the Raspberry Pi.

Options are:
    --fancy-sauce-use-cache:    Makes use of fancy-sauce cache. Path to fancy-sauce cache must be specified.
    --fancy-sauce-build-cache:  Builds fancy-sauce cache. Path to fancy-sauce must be specified.
                                A valid config for fancy sauce must also exist.
    --device:                   Build directly onto a SD card instead of creating a image.
    --fancy-sauce-path:         Path to fancy sauce directory.
    --log:                      Log this scripts stdout and stderr streams to build.log file in cwd.
__EOF__
}

function on_cancel()
{
    if [[ "${loop_device}" != "" ]]; then
        echo "freeing loop device ${loop_device}"
        losetup -d ${loop_device}
    fi

    if [[ "${image}" != "" ]]; then
        kpartx -d ${image}
        dmsetup remove_all
        echo "creating ${image} cancelled"
        losetup -d ${rootp}
        losetup -d ${bootp}
        echo "freeing loop device ${rootp}"
        echo "freeing loop device ${bootp}"
    fi

    exit
}

# Start logging
#   Redirects stdout and stderr streams to build.log file
function start_logging()
{
    rm build.log
    exec >  >(tee -a build.log)
    exec 2> >(tee -a build.log>&2)
}

if [ ${EUID} -ne 0 ]; then
    echo "this tool must be run as root"
    exit 1
fi

sauce_path=""
device=""
loop_device=""
build_sauce_cache=0
deb_mirror="http://archive.raspbian.org/raspbian"
deb_local_mirror="http://localhost:3142/archive.raspbian.org/raspbian"
sauce_cache_mnt_path="/opt/cache/"
rootfs_mirror="${deb_local_mirror}"
sauce_cache_path=""

while [[ $# > 0 ]]
do
    key="$1"
    shift

    case $key in
        --fancy-sauce-path)
        if [ "x${1}" == "x" ]; then
            echo "Path to fancy sauce missing"
            usage
            exit 1
        fi
        sauce_path=$1
        echo "Fancy sauce path: ${sauce_path}"
        shift
        ;;

        --fancy-sauce-build-cache)
        build_sauce_cache=1
        echo "Building fancy sauce cache"
        ;;

        --fancy-sauce-use-cache)
        if [ "x${1}" == "x" ]; then
            echo "Path to cache missing"
            usage
            exit 1
        fi
        sauce_cache_path=$1
        deb_local_mirror="file://${sauce_cache_path}"
        rootfs_mirror="file:${sauce_cache_mnt_path}"
        echo "Using fancy sauce cache from: ${sauce_cache_path}"
        shift
        ;;

        --device)
        device=$1
        if ! [ -b ${device} ]; then
            echo "${device} is not a block device"
            exit 1
        fi
        shift
        ;;

        --log)
        start_logging
        ;;

        *)
        usage
        exit 1
        ;;

        -h|--help)
        usage
        exit 1
        ;;
    esac
done

trap on_cancel SIGHUP SIGINT SIGTERM

if [ "x${sauce_path}" == "x" ]; then
    echo "Path to fancy sauce missing"
    usage
    exit 1
fi

if [ "${deb_local_mirror}" == "" ]; then
    deb_local_mirror=${deb_mirror}
fi

bootsize="64M"
deb_release="wheezy"
rootfs_fancy_sauce_dir="/opt/fancy-sauce"
install_later_path="/etc/later/later.sh"
install_later_cache_path="/etc/later/cache"

relative_path=`dirname $0`

# locate path of this script
absolute_path=`cd ${relative_path}; pwd`

# locate path of delivery content
delivery_path=`cd ${absolute_path}/../delivery; pwd`

# define destination folder where created image file will be stored
buildenv=`cd ${absolute_path}; cd ..; mkdir -p rpi/images; cd rpi; pwd`
# buildenv="/tmp/rpi"

# cd ${absolute_path}

rootfs="${buildenv}/rootfs"
bootfs="${rootfs}/boot"

today=`date +%Y%m%d`

image=""

if [ "${device}" == "" ]; then
    echo "no block device given, just creating an image"
    mkdir -p ${buildenv}
    image="${buildenv}/images/raspbian_basic_${deb_release}_${today}.img"
    dd if=/dev/zero of=${image} bs=1MB count=3800
    loop_device=`losetup -f --show ${image}`
    if [ $? -ne 0 ]; then
        echo "no loop devices available, quitting"
        exit 1
    fi
    echo "image ${image} created and mounted as ${loop_device}"
    device=${loop_device}
else
    dd if=/dev/zero of=${device} bs=512 count=1
fi

fdisk ${device} << EOF
n
p
1

+${bootsize}
t
c
n
p
2


w
EOF


if [ "${image}" != "" ]; then
    device=`kpartx -va ${image} | sed -E 's/.*(loop[0-9])p.*/\1/g' | head -1`
    device="/dev/mapper/${device}"
    bootp=${device}p1
    rootp=${device}p2
else
    if ! [ -b ${device}1 ]; then
        bootp=${device}p1
        rootp=${device}p2
        if ! [ -b ${bootp} ]; then
            echo "uh, oh, something went wrong, can't find bootpartition neither as ${device}1 nor as ${device}p1, exiting."
            exit 1
        fi
    else
        bootp=${device}1
        rootp=${device}2
    fi
fi

mkfs.vfat ${bootp}
mkfs.ext4 ${rootp}

umount -l ${bootp}

umount -l ${rootfs}${sauce_cache_mnt_path}
umount -l ${rootfs}${rootfs_fancy_sauce_dir}
umount -l ${rootfs}/usr/src/delivery
umount -l ${rootfs}/dev/pts
umount -l ${rootfs}/dev
umount -l ${rootfs}/sys
umount -l ${rootfs}/proc

umount -l ${rootfs}
umount -l ${rootp}


mkdir -p ${rootfs}

mount ${rootp} ${rootfs}

mkdir -p ${rootfs}/proc
mkdir -p ${rootfs}/sys
mkdir -p ${rootfs}/dev
mkdir -p ${rootfs}/dev/pts
mkdir -p ${rootfs}/usr/src/delivery
if [[ "${sauce_cache_path}" != "" ]]; then
    mkdir -p ${rootfs}${sauce_cache_mnt_path}
fi
if [[ "${sauce_path}" != "" ]]; then
    mkdir -p ${rootfs}${rootfs_fancy_sauce_dir}
fi

mount -t proc none ${rootfs}/proc
mount -t sysfs none ${rootfs}/sys
mount -o bind /dev ${rootfs}/dev
mount -o bind /dev/pts ${rootfs}/dev/pts
mount -o bind ${delivery_path} ${rootfs}/usr/src/delivery
if [[ "${sauce_cache_path}" != "" ]]; then
    mount -o bind ${sauce_cache_path} ${rootfs}${sauce_cache_mnt_path}
fi
if [[ "${sauce_path}" != "" ]]; then
    mount -o bind ${sauce_path} ${rootfs}${rootfs_fancy_sauce_dir}
fi

cd ${rootfs}

debootstrap --foreign --arch armhf ${deb_release} ${rootfs} ${deb_local_mirror}
cp /usr/bin/qemu-arm-static usr/bin/
LANG=C chroot ${rootfs} /debootstrap/debootstrap --second-stage

mount ${bootp} ${bootfs}

if [[ "${sauce_cache_path}" != "" ]]; then
    echo "deb ${rootfs_mirror} ${deb_release} main" > etc/apt/sources.list
else
    echo "deb ${rootfs_mirror} ${deb_release} main contrib non-free
deb-src ${rootfs_mirror} ${deb_release} main contrib non-free
" > etc/apt/sources.list
fi

echo "dwc_otg.lpm_enable=0 console=ttyAMA0,115200 kgdboc=ttyAMA0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 rootwait" > boot/cmdline.txt

echo "proc            /proc           proc    defaults        0       0
/dev/mmcblk0p1  /boot           vfat    defaults        0       0
" > etc/fstab

echo "raspberrypi" > etc/hostname

echo "auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
auto wlan0 
iface wlan0 inet dhcp
" > etc/network/interfaces

echo "vchiq
snd_bcm2835
" >> etc/modules

echo "console-common	console-data/keymap/policy	select	Select keymap from full list
console-common	console-data/keymap/full	select	us
" > debconf.set

echo "#!/bin/bash
debconf-set-selections /debconf.set
rm -f /debconf.set

export FANCY_SAUCE_PATH=${rootfs_fancy_sauce_dir}
export INSTALL_LATER_PATH=${install_later_path}
export INSTALL_LATER_CACHE_PATH=${install_later_cache_path}

cd /usr/src/delivery
source functions.sh
AptUpdate
AptInstall git-core binutils ca-certificates
AptInstall curl locales console-common ntp openssh-server less vim

curl -L -k --output "/usr/bin/rpi-update" https://github.com/Hexxeh/rpi-update/raw/master/rpi-update
chmod +x /usr/bin/rpi-update
mkdir -p /lib/modules
touch /boot/start.elf
rpi-update

# execute install script at mounted external media (delivery contents folder)
cd /usr/src/delivery
./install.sh
echo "INSTALL DONE"

if [ ${build_sauce_cache} -eq 1 ]
then
    echo "Starting fancy sauce"
    pushd ${rootfs_fancy_sauce_dir}
    echo "Preparing fancy-sauce"
    ./prereqs.sh

    echo "Building package manifest"
    ./build_installed_manifest.sh

    echo "Downloading packages"
    ./download_package.sh
    popd
fi

echo \"root:raspberry\" | chpasswd
sed -i -e 's/KERNEL\!=\"eth\*|/KERNEL\!=\"/' /lib/udev/rules.d/75-persistent-net-generator.rules
rm -f /etc/udev/rules.d/70-persistent-net.rules
rm -f third-stage
" > third-stage
chmod +x third-stage
LANG=C chroot ${rootfs} /third-stage

echo "deb ${deb_mirror} ${deb_release} main contrib non-free
" > etc/apt/sources.list

cd ${rootfs}

sync
sleep 15

umount -l ${bootp}

umount -l ${rootfs}${sauce_cache_mnt_path}
umount -l ${rootfs}${rootfs_fancy_sauce_dir}
umount -l ${rootfs}/usr/src/delivery
umount -l ${rootfs}/dev/pts
umount -l ${rootfs}/dev
umount -l ${rootfs}/sys
umount -l ${rootfs}/proc

umount -l ${rootfs}
umount -l ${rootp}

echo "finishing ${image}"

if [[ "${loop_device}" != "" ]]; then
    echo "freeing loop device ${loop_device}"
    losetup -d ${loop_device}
fi

if [[ "${image}" != "" ]]; then
    kpartx -d ${image}
    dmsetup remove_all
    echo "created image ${image}"
    echo "freeing loop device ${rootp}"
    losetup -d ${rootp}
    echo "freeing loop device ${bootp}"
    losetup -d ${bootp}
fi

echo "done."
