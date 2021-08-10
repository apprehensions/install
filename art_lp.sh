#!/bin/bash
BTRFS_OPTS="rw,relatime,ssd,compress=zstd,space_cache,commit=120"
export ROOT="/dev/nvme0n1p2"
ESP="/dev/nvme0n1p1"
export HOST=art_lp
export HOSTNAME=yoga

mkfs.vfat -nBL -F32 $ESP
mkfs.btrfs -L root -f $ROOT
mount -o $BTRFS_OPTS $ROOT /mnt
mkdir /mnt/boot
mount -o rw,noatime $ESP /mnt/boot

sed -ibak -e '37s/.//' -e '37s/5/20/' /etc/pacman.conf
basestrap /mnt base base-devel linux linux-firmware linux-headers intel-ucode btrfs-progs openrc elogind-openrc iwd-openrc dhcpcd-openrc artix-archlinux-support grub os-prober efibootmgr
mv /etc/pacman.confbak /etc/pacman.conf
fstabgen -U /mnt >> /mnt/etc/fstab

sed '1,/^# - post$/d' $0 > /mnt/post.sh
cp ./modules /mnt/ -r
chmod a+x /mnt/post.sh
artix-chroot /mnt ./post.sh
umount -R /mnt
exit

# - post

./modules/10-needed.sh
./modules/30-pkg.sh
./modules/31-vid.sh
./modules/40-boot.sh
./modules/51-net.sh
./modules/99-user.sh
rc-update add iwd default
rm /modules -rf
rm /post.sh
