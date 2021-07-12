#!/bin/bash
BTRFS_OPTS="rw,relatime,ssd,compress=zstd,space_cache,commit=120"
ROOT="/dev/sda2"
ESP="/dev/sda1"
HOSTNAME="br"

mkfs.vfat -nESP -F32 $ESP
mkfs.btrfs -L artix -f $ROOT
mount -o $BTRFS_OPTS $ROOT /mnt
mkdir /mnt/efi
mount -o rw,noatime $ESP /mnt/efi

sed -ibak -e '37s/.//' -e '37s/5/20/' /etc/pacman.conf
basestrap /mnt base base-devel linux linux-firmware linux-headers intel-ucode nvidia nvidia-settings btrfs-progs runit elogind-runit dhcpcd-runit
mv /etc/pacman.confbak /etc/pacman.conf
fstabgen -U /mnt >> /mnt/etc/fstab

sed '1,/^# - post$/d' $0 > /mnt/post.sh
chmod a+x /mnt/post.sh
artix-chroot /mnt ./post.sh
umount -R /mnt

# - post

echo "LANG=en_US.UTF-8" > /etc/locale.conf
sed -i '177s/.//' /etc/locale.gen
locale-gen
ln -sf /usr/share/zoneinfo/Asia/Riyadh /etc/localtime
hwclock --systohc

sed -i -e '33s/.//' -e '37s/.//' -e '93,94s/.//' /etc/pacman.conf
pacman --noconfirm -Sy grub os-prober efibootmgr wget git zsh
git clone https://aur.archlinux.org/paru.git /usr/src/paru && chmod 777 /usr/src/paru

echo $HOSTNAME > /etc/hostname
echo -e "nameserver 1.1.1.1\nnameserver 1.0.0.1" > /etc/resolv.conf
echo -e "127.0.0.1 localhost\n::1       localhost \n127.0.1.1 $HOSTNAME.localdomain $HOSTNAME" > /etc/hosts
ln -s /etc/runit/sv/dhcpcd /etc/runit/runsvdir/default/
ln -s /etc/runit/sv/sshd /etc/runit/runsvdir/default/

grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id='Artix Linux'
grub-mkconfig -o /boot/grub/grub.cfg

sed -i "/GETTY_ARGS=/s/\"$/ --autologin wael&/" /etc/runit/sv/agetty-tty1/conf
sed -i '82s/. //' /etc/sudoers
useradd -mG wheel,audio,video -s /bin/zsh wael
passwd && passwd wael
