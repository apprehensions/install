#!/bin/bash
export BTRFS_OPTS="rw,relatime,ssd,compress=zstd,space_cache,commit=120"
export ROOT="/dev/nvme0n1p2"
export ESP="/dev/nvme0n1p1"
export HOSTNAME=yoga
source ./mods

mkfs_part
mkdir /mnt/efi
mount -o rw,noatime $ESP /mnt/efi

void_strap
void_needed
xbps_do

sed '1,/^# - post$/d' $0 > /mnt/post.sh
chmod a+x /mnt/post.sh
cp ./mods /mnt/
chroot /mnt ./post.sh
umount -R /mnt
exit

# - post
. /mods

void_sv_do
xbps-install -y iwd openresolv
ln -sv /etc/sv/iwd /etc/runit/runsvdir/default
iwd_do
void_make_me
void_autologin
rm /mods
rm /post.sh
