#!/bin/bash
BTRFS_OPTS="rw,relatime,ssd,compress=zstd,space_cache,commit=120"
HOSTNAME=yoga
HOST=lp-ao
ROOT="/dev/nvme0n1p2"
ESP="/dev/nvme0n1p1"
read PASS

mkfs.vfat -nESP -F32 $ESP
echo -n $PASS | cryptsetup -v luksFormat -s=512 $ROOT -d -
echo -n $PASS | cryptsetup open $ROOT kroot -d -
mkfs.btrfs -L kroot /dev/mapper/kroot
mount -o $BTRFS_OPTS /dev/mapper/kroot /mnt
mkdir /mnt/boot
mount -o rw,noatime $ESP /mnt/boot

sed -ibak -e '37s/.//' -e '37s/5/20/' /etc/pacman.conf
basestrap /mnt base base-devel linux linux-firmware linux-headers intel-ucode btrfs-progs runit elogind-runit iwd-runit dhcpcd-runit artix-archlinux-support
mv /etc/pacman.confbak /etc/pacman.conf
fstabgen -U /mnt >> /mnt/etc/fstab

sed '1,/^# - post$/d' $0 > /mnt/post.sh
cp ./modules /mnt/ -r
chmod a+x /mnt/post.sh
artix-chroot /mnt ./post.sh
umount -R /mnt
cryptsetup close kroot
exit

# - post

./modules/locale.sh
./modules/time.sh
./modules/iden.sh
./modules/grub.sh
./modules/time.sh
./modules/user.sh
./modules/autologin.sh
./modules/pacman.sh
pacman --noconfirm -Sy grub os-prober efibootmgr wget git zsh exa
ln -sv /etc/runit/sv/dhcpcd /etc/runit/runsvdir/default/
ln -sv /etc/runit/sv/sshd /etc/runit/runsvdir/default/
ln -sv /etc/runit/sv/iwd /etc/runit/runsvdir/default/
rm /modules
rm /post.sh
