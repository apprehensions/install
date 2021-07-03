#!/bin/bash
HOSTNAME=worchine
NAME=not

# enable parallel downloads (the stupid way)
sed -ibak -e '37s/.//' -e '37s/5/10/' /etc/pacman.conf
pacman --noconfirm -Sy archlinux-keyring
reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
pacstrap /mnt linux linux-firmware linux-headers base base-devel btrfs-progs amd-ucode grub
cp /etc/pacman.confbak /etc/pacman.conf
genfstab -U /mnt >> /mnt/etc/fstab

echo $HOSTNAME > /mnt/etc/hostname
echo -e "127.0.0.1 localhost\n::1       localhost \n127.0.1.1 $HOSTNAME.localdomain $HOSTNAME" > /mnt/etc/hosts
echo -e "[Service]\nExecStart=\nExecstart=-/usr/bin/agetty --noissue --autologin $NAME --noclear %I $TERM" > /mnt/etc/systemd/system/getty@tty1.service.d/override.conf
echo -e "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
sed -i '177s/.//' /mnt/etc/locale.gen
arch-chroot /mnt locale-gen

arch-chroot /mnt timedatectl set-ntp true
arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/Kiev /etc/localtime
arch-chroot /mnt hwclock --systohc

sed -i -e '33s/.//' -e '37s/.//' -e '93,94s/.//' /mnt/etc/pacman.conf
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/
arch-chroot /mnt pacman --noconfirm -Syu git wget neofetch

arch-chroot /mnt grub-install --target=i386-pc /dev/sda
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

echo -e "[Match]\nName=eno1\n\n[Network]\nDHCP=yes" > /mnt/etc/systemd/network/lan.network
arch-chroot /mnt systemctl enable systemd-networkd

sed -i '82s/. //' /mnt/etc/sudoers
arch-chroot /mnt useradd -m -G wheel -s /bin/bash $user
echo -e "\n$(tput bold)$user password: $(tput sgr0)"
arch-chroot /mnt passwd $user 
echo -e "\n$(tput bold)root password: $(tput sgr0)"
arch-chroot /mnt passwd

printf 'FUCKYOU\n%.0s' {1..100}
umount -R /mnt
reboot
