#!/bin/bash

USBTMP='/mnt/knoppixtmp'
ISOTMP='/mnt/knxiso'

check_dependency() {
  echo -n "Checking for $1..."

  TEST=`which $1`
  EXISTS=${#TEST}

  if [ ${EXISTS} -gt 0 ]; then
    echo "[OK]"
  else
    echo "[FAILED]"
    echo "You need to install $1 before proceeding."
    exit 1
  fi
}

makeimage() {
	size=`fdisk -l | grep $1 | grep Disk | awk '{ print $3 }'`
	
	
	echo "Specified disk size appears to be $size GB. Please enter the disk size (as a whole integer, round UP to the nearest gigabyte if necessary)"
	read size
	
	
	#echo -n "Zeroing disk..."
	#dd if=/dev/zero of=$1
	
	echo "done"
	
	if [ $size == 1 ]; then
		echo "Running: mkdiskimage -4 $1 0 64 32"
		mkdiskimage -4 $1 0 64 32
	fi
	
	if  (($size > 1 )) &&  (($size <= 2)) ; then
		echo "Running: mkdiskimage -4 $1 0 128 32"
		mkdiskimage -4 $1 0 128 32
	fi
	
	if  (($size > 2 )) &&  (($size <= 8)) ; then
		echo "Running: mkdiskimage -F -4 $1 0 255 63"
		mkdiskimage -F -4 $1 0 255 63
	fi
	
	if (($size > 8 )); then
		echo "You really should use 8GB or less. You may have to do this manually if the following command fails. See: http://knoppix.net/wiki/Bootable_USB_Key"
		echo "Running: mkdiskimage -F -4 $1 0 255 63"
		mkdiskimage -F -4 $1 0 255 63
	fi	
}

usage() {
  echo ""
  echo "This program MUST be run as root"
  echo ""
  echo "Usage: makekusb [/dev/device] [/path/to/knoppix.iso] [--skip-image]"
  echo ""
  exit 1
}

if [ $(whoami) != "root" ]; then
  echo "$0 should be run as root! You're not root. Magic 8 ball says: RTFM."
  usage
fi

check_dependency syslinux
check_dependency mkdiskimage

echo -n "Source ISO exists..."

if [ ! -f $2 ]; then
	echo "[NO]"
	echo "$2 does not appear to exist."
	exit 1;
else 
	echo "[YES]"
fi

if [ $# -eq 0 ]; then
  echo "Oops. Perhaps you didn't RTFM?"
  usage
fi


if [ ! -d  $USBTMP ]; then
	mkdir $USBTMP
fi

if [ ! -d $ISOTMP ]; then
	mkdir $ISOTMP
fi

echo "Removing old files from $USBTMP.."
rm -vfr $USBTMP/*

echo "Unmounting $ISOTMP just in case..."
umount $ISOTMP

USBBOOTPARTITION="$1"4

echo "Mounting $2 -> $ISOTMP"
mount $2 $ISOTMP

echo "You are about to DESTROY $1. It will be zeroed out, and completely"
echo "erased before being turned into a Knoppix USB key. Are you sure you want to do"
echo "this? [yes/NO]"

read test
if [ "$test" != "yes" ]; then
	echo "You must agree by typing 'yes'. Quitting."
	exit 0;
fi

if [ "$3" != "--skip-image" ]; then
	makeimage
fi


echo "Running syslinux: syslinux -s $USBBOOTPARTITION"
syslinux -s "$1"4

echo "Mounting disk to prepare for file copy..."

mount $USBBOOTPARTITION $USBTMP

echo "Syncing boot to USB stick..."
rsync -av --progress $ISOTMP/boot/isolinux/ $USBTMP

mv $USBTMP/isolinux.cfg $USBTMP/syslinux.cfg
rm $USBTMP/isolinux.bin

echo "Syncing files to USB Stick..."

rsync -av --progress $ISOTMP $USBTMP --exclude=boot

echo "Syncing file system"
sync
echo "Unmounting $USBBOOTPARTITION"
umount $USBBOOTPARTITION
echo "Syncing file system (again)"
sync

echo "Complete!"