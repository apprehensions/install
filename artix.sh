#!/usr/bin/env bash
export ROOT="/dev/sda2"
export ESP="/dev/sda1"
source modules

mkrm
mkespm

sed -ibak -e '37s/.//' -e '37s/5/50/' /etc/pacman.conf

basestrap /mnt linux linux-firmware linux-headers intel-ucode \
               base base-devel btrfs-progs \
               s6-base elogind-s6
          
mv /etc/pacman.confbak /etc/pacman.conf

fstabgen -U /mnt >> /mnt/etc/fstab

echo_host_related
sed_pacman_conf
cat_eof_iwd_main_conf

sed '1,/^# - post$/d' $0 > /mnt/post-install.sh
cp modules /mnt/
chmod a+x /mnt/post-install.sh
artix-chroot /mnt ./post-install.sh
umount -R /mnt
post_install_goodbye
exit

# - post
source /modules
c_locale_set
c_clock
c_artix_archlinux_support

pacman --noconfirm -Sy zsh terminus-font grub os-prober efibootmgr \
                       nvidia-dkms nvidia-utils nvidia-settings lib32-nvidia-utils \
                       dhcpcd-s6 iwd-s6

s6-rc-bundle-update add default iwd dhcpcd

c_grub_install
c_nvidia_modules
c_useradd_wael
