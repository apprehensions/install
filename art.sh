#!/bin/bash
set -x
BTRFS_OPTS="rw,relatime,ssd,compress=zstd,space_cache,commit=120"
ROOT="/dev/sda2"
ESP="/dev/sda1"
export HOST=pc-ao
export HOSTNAME=br

mkfs.vfat -nESP -F32 $ESP
mkfs.btrfs -L artix -f $ROOT
mount -o $BTRFS_OPTS $ROOT /mnt
mkdir /mnt/efi
mount -o rw,noatime $ESP /mnt/efi

sed -ibak -e '37s/.//' -e '37s/5/20/' /etc/pacman.conf
basestrap /mnt base base-devel linux linux-firmware linux-headers intel-ucode nvidia nvidia-settings btrfs-progs openrc elogind-openrc dhcpcd-openrc artix-archlinux-support grub efibootmgr os-prober
mv /etc/pacman.confbak /etc/pacman.conf
fstabgen -U /mnt >> /mnt/etc/fstab

sed '1,/^# - post$/d' $0 > /mnt/post.sh
cp ./modules /mnt/ -r
chmod a+x /mnt/post.sh
artix-chroot /mnt ./post.sh
umount -R /mnt
exit

# - post

./modules/10-locale.sh
./modules/20-time.sh
./modules/21-iden.sh
./modules/30-pacman.sh
./modules/40-boot.sh
./modules/50-sv.sh
./modules/99-user.sh
rm /modules -rf
rm /post.sh
