#!/bin/sh

/bin/busybox --install -s

[ -d /dev ] || mkdir -m 0755 /dev
[ -d /root ] || mkdir -m 0700 /root
[ -d /sys ] || mkdir /sys
[ -d /proc ] || mkdir /proc
[ -d /tmp ] || mkdir /tmp
mkdir -p /var/lock
mount -t sysfs -o nodev,noexec,nosuid sysfs /sys
mount -t proc -o nodev,noexec,nosuid proc /proc
# Some things don't work properly without /etc/mtab.
ln -sf /proc/mounts /etc/mtab

grep -q '\<quiet\>' /proc/cmdline || echo "Loading, please wait..."

# Note that this only becomes /dev on the real filesystem if udev's scripts
# are used; which they will be, but it's worth pointing out
if ! mount -t devtmpfs -o mode=0755 udev /dev; then
	echo "W: devtmpfs not available, falling back to tmpfs for /dev"
	mount -t tmpfs -o mode=0755 udev /dev
	[ -e /dev/console ] || mknod -m 0600 /dev/console c 5 1
	[ -e /dev/null ] || mknod /dev/null c 1 3
fi
mkdir /dev/pts
mount -t devpts -o noexec,nosuid,gid=5,mode=0620 devpts /dev/pts || true
mount -t tmpfs -o "noexec,nosuid,size=10%,mode=0755" tmpfs /run
mkdir /run/initramfs
# compatibility symlink for the pre-oneiric locations
ln -s /run/initramfs /dev/.initramfs

# Export the dpkg architecture
DPKG_ARCH=armhf

# Set modprobe env
export MODPROBE_OPTIONS="-qb"

# Export relevant variables
export ROOT=
export ROOTDELAY=
export ROOTFLAGS=
export ROOTFSTYPE=
export IP=
export BOOT=
export BOOTIF=
export UBIMTD=
export break=
export init=/sbin/init
export quiet=n
export readonly=y
export rootmnt=/root
export debug=
export panic=
export blacklist=
export resume=
export resume_offset=
export recovery=

# mdadm needs hostname to be set. This has to be done before the udev rules are called!
if [ -f "/etc/hostname" ]; then
        /bin/hostname -b -F /etc/hostname 2>&1 1>/dev/null
fi

MODULES=most
BUSYBOX=y
COMPCACHE_SIZE=""
COMPRESS=gzip
BOOT=local
DEVICE=
NFSROOT=auto
#. /scripts/functions

# Parse command line options
for x in $(cat /proc/cmdline); do
	case $x in
	init=*)
		init=${x#init=}
		;;
	root=*)
		ROOT=${x#root=}
		case $ROOT in
		LABEL=*)
			ROOT="${ROOT#LABEL=}"

			# support any / in LABEL= path (escape to \x2f)
			case "${ROOT}" in
			*/*)
			if command -v sed >/dev/null 2>&1; then
				ROOT="$(echo ${ROOT} | sed 's,/,\\x2f,g')"
			else
				if [ "${ROOT}" != "${ROOT#/}" ]; then
					ROOT="\x2f${ROOT#/}"
				fi
				if [ "${ROOT}" != "${ROOT%/}" ]; then
					ROOT="${ROOT%/}\x2f"
				fi
				IFS='/'
				newroot=
				for s in $ROOT; do
					newroot="${newroot:+${newroot}\\x2f}${s}"
				done
				unset IFS
				ROOT="${newroot}"
			fi
			esac
			ROOT="/dev/disk/by-label/${ROOT}"
			;;
		UUID=*)
			ROOT="/dev/disk/by-uuid/${ROOT#UUID=}"
			;;
		/dev/nfs)
			[ -z "${BOOT}" ] && BOOT=nfs
			;;
		esac
		;;
	rootflags=*)
		ROOTFLAGS="-o ${x#rootflags=}"
		;;
	rootfstype=*)
		ROOTFSTYPE="${x#rootfstype=}"
		;;
	rootdelay=*)
		ROOTDELAY="${x#rootdelay=}"
		case ${ROOTDELAY} in
		*[![:digit:].]*)
			ROOTDELAY=
			;;
		esac
		;;
	resumedelay=*)
		RESUMEDELAY="${x#resumedelay=}"
		;;
	loop=*)
		LOOP="${x#loop=}"
		;;
	loopflags=*)
		LOOPFLAGS="-o ${x#loopflags=}"
		;;
	loopfstype=*)
		LOOPFSTYPE="${x#loopfstype=}"
		;;
	cryptopts=*)
		cryptopts="${x#cryptopts=}"
		;;
	nfsroot=*)
		NFSROOT="${x#nfsroot=}"
		;;
	netboot=*)
		NETBOOT="${x#netboot=}"
		;;
	ip=*)
		IP="${x#ip=}"
		;;
	boot=*)
		BOOT=${x#boot=}
		;;
	ubi.mtd=*)
		UBIMTD=${x#ubi.mtd=}
		;;
	resume=*)
		RESUME="${x#resume=}"
		;;
	resume_offset=*)
		resume_offset="${x#resume_offset=}"
		;;
	noresume)
		noresume=y
		;;
	panic=*)
		panic="${x#panic=}"
		case ${panic} in
		*[![:digit:].]*)
			panic=
			;;
		esac
		;;
	quiet)
		quiet=y
		;;
	ro)
		readonly=y
		;;
	rw)
		readonly=n
		;;
	debug)
		debug=y
		quiet=n
		exec >/run/initramfs/initramfs.debug 2>&1
		set -x
		;;
	debug=*)
		debug=y
		quiet=n
		set -x
		;;
	break=*)
		break=${x#break=}
		;;
	break)
		break=premount
		;;
	blacklist=*)
		blacklist=${x#blacklist=}
		;;
	netconsole=*)
		netconsole=${x#netconsole=}
		;;
	BOOTIF=*)
		BOOTIF=${x#BOOTIF=}
		;;
	hwaddr=*)
		BOOTIF=${x#BOOTIF=}
		;;
	recovery)
		recovery=y
		;;
	esac
done

if [ -n "${noresume}" ]; then
	export noresume
	unset resume
else
	resume=${RESUME:-}
fi

#echo "Starting TFTP download to microSD card"
#tftp -g -r cubieboard2.img -l - 192.168.2.105 | dd of=/dev/mmcblk0 bs=65536
#echo "Finished TFTP download to microSD card"
sh

