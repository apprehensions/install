#!/usr/bin/env -S sh -xe
. source.conf
sgdisk -Z ${DISK}
sgdisk -a 2048 -o ${DISK}
sgdisk -n 1:0:+512M ${DISK} # /dev/sda1
sgdisk -n 2:0:0 ${DISK} # /dev/sda2
mkfs.vfat -F 32 -n ${ESPLABEL} ${DISK}1
mkfs.btrfs -L ${ROOTLABEL} -f ${DISK}2
sgdisk -t 1:ef00 ${DISK} 
sgdisk -t 2:8300 ${DISK} 
mount -o ${BTRFSOPTS} ${DISK}2 /mnt
mkdir -pv /mnt/boot
mount -o noatime ${DISK}1 /mnt/boot
