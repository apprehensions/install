#!/bin/bash
export BTRFS_OPTS="rw,noatime,ssd,compress=zstd,space_cache,commit=120"
export ROOT="/dev/sda2"
export ESP="/dev/sda1"
export DIST=arch
export PLAT=pc
export HOSTNAME=br

./modules/01-disk.sh
mkdir /mnt/boot
mount -o rw,noatime $ESP /mnt/boot

reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
sed -ibak -e '37s/.//' -e '37s/5/24/' /etc/pacman.conf
pacman --noconfirm -Sy archlinux-keyring
pacstrap /mnt linux linux-firmware linux-headers base base-devel btrfs-progs nvidia nvidia-settings
mv /etc/pacman.confbak /etc/pacman.conf
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/
genfstab -U /mnt >> /mnt/etc/fstab

sed '1,/^# - post$/d' $0 > /mnt/post.sh
chmod a+x /mnt/post.sh
arch-chroot /mnt ./post.sh
umount -R /mnt
exit

# - post
./modules/10-needed.sh
./modules/30-pkg.sh
./modules/31-vid.sh
./modules/40-boot.sh
./modules/51-net.sh
echo -e "[Match]\nName=eno1\n\n[Network]\nDHCP=yes" > /etc/systemd/network/lan.network
systemctl enable systemd-networkd
./modules/99-user.sh
rm /modules -rf
rm /post.sh
