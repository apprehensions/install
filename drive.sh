#!/bin/bash
read -p "partition disk? [y/n]" answer

if [[ $answer = y ]] ; then
	echo "disk: "
	read disk
	cfdisk $disk
fi
	
echo "partition: "
read part
mkfs.btrfs $part -f
mount $part /mnt

#meant for ssd only
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
umount /mnt
mount -o rw,ssd,relatime,compress=zstd,space_cache,discard=async,subvol=@ $part /mnt
mkdir /mnt/home
mount -o rw,ssd,relatime,compress=zstd,space_cache,discard=async,subvol=@home $part /mnt/home