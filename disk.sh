#!/usr/bin/env -S bash -xe
_disk=/dev/sda
sgdisk -Z ${_disk}
sgdisk -a 2048 -o ${_disk}
sgdisk -n 1:0:+512M ${_disk} # /dev/sda1
sgdisk -n 2:0:0 ${_disk} # /dev/sda2
mkfs.vfat -F 32 -n ESP ${_disk}1
mkfs.btrfs -L EPHEMERA -f ${_disk}2
sgdisk -t 1:ef00 ${_disk} 
sgdisk -t 2:8300 ${_disk} 
mount -o rw,noatime,ssd,space_cache=v2,discard=async ${_disk}2 /mnt
mkdir -pv /mnt/boot
mount -o noatime ${_disk}1 /mnt/boot
