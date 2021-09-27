#!/bin/bash
export ROOT="/dev/sda2"
export ESP="/dev/sda1"
source modules

mkrm
mkespm
echo -e "t\n1\n1\nw" | fdisk /dev/sda

reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
sed -ibak -e '37s/.//' -e '37s/5/50/' /etc/pacman.conf

pacstrap /mnt linux linux-firmware linux-headers intel-ucode \
              base base-devel btrfs-progs

mv /etc/pacman.confbak /etc/pacman.conf
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/
genfstab -U /mnt >> /mnt/etc/fstab

timedatectl set-ntp true
echo_host_related
echo_vconsole
sed_pacman_conf

cat <<EOF > /mnt/etc/systemd/network/lan.network
[Match]
Name=eno2

[Network]
DHCP=yes
EOF 

cat_eof_iwd_main_conf
post_chroot arch

# - ====
# - post
source /modules
c_locale_set
c_clock

pacman --noconfirm -Sy zsh terminus-font  \
                       nvidia-dkms nvidia-utils nvidia-settings lib32-nvidia-utils \

systemctl enable systemd-networkd
systemctl enable iwd

c_modk
bootctl install
cat <<EOF > /boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options rw root=$ROOT quiet splash
EOF
echo -e "timeout 5\nconsole-mode max" > /boot/loader/loader.conf

c_useradd_wael
getty_autologin
