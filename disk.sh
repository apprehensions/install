#!/usr/bin/env -S bash -xe
source vars.conf

disk() {
  # zap all on disk, idk why lol
  sgdisk -Z $DISK
  # create gpt table with sector size 2048
  sgdisk -a 2048 -o $DISK
  # created partition 512M at the start of the disk
  sgdisk -n 1:0:+512M $DISK
  # partition with the rest of the disk
  sgdisk -n 2:0:0 $DISK
}

make() {
  mkfs.vfat -F 32 -n ESP $ESP
  mkfs.btrfs -L ${HOSTNAMESTRAP^^} -f $ROOT
  sgdisk -t $ESPN:ef00 $DISK
  sgdisk -t $ROOTN:8300 $DISK
}

mount() {
  mkdir -pv /mnt/boot
  mount -o $BTRFS_FLAGS $ROOT /mnt
  mount -o noatime $ESP /mnt/boot
}

echo "make, mount, disk"
$1
