#!/bin/bash
# https://github.com/Bugswriter/arch-linux-magic/blob/master/arch_install.sh
# https://gitlab.com/eflinux/arch-basic/-/blob/master/install-uefi.sh
# i dont know how to use bash,sed,echo properly.
set -x
name=br
read root
read esp

mkfs.btrfs -L arch -f $root
mkfs.vfat -n EFI -F 32 $esp
mount $root /mnt
btrfs subvolume create /mnt/@
btrfs subvolume set-default /mnt/@
umount -R /mnt
mount -o compress=zstd,subvol=@ $root /mnt
mkdir /mnt/boot
mount $esp /mnt/boot

reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
sed -i '37s/.//' /etc/pacman.conf && sed -i '37s/5/12/' /etc/pacman.conf
pacstrap /mnt linux linux-firmware linux-headers base base-devel intel-ucode btrfs-progs nvidia grub efibootmgr
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/
genfstab -U /mnt >> /mnt/etc/fstab
echo -e $name > /etc/hostname
echo -e "127.0.0.1 localhost\n::1       localhost \n127.0.0.1 $name.localdomain $name" > /mnt/etc/hosts
echo -e "[Match]\nName=eno1\n\n[Network]\nDHCP=yes" > /mnt/etc/systemd/network/lan.network
mkdir /mnt/etc/systemd/system/getty@tty1.service.d
echo -e "[Service]\nExecStart=\nExecstart=-/usr/bin/agetty --skip-login --nonewline --noissue --autologin wael\nTTYVTDisallocate=no" > /mnt/etc/systemd/system/getty@tty1.service.d/override.conf
arch-chroot /mnt bootctl install
echo -e "title   Arch Linux\nlinux   /vmlinuz-linux\ninitrd  /intel-ucode.img\ninitrd  /initramfs-linux.img\noptions rw root=$root rootflags=subvol=@ loglevel=4" > /boot/loader/entries/arch.conf
echo -e "timeout 1\nconsole-mode max" > /boot/loader/loader.conf
echo -e "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
sed -i '177s/.//' /mnt/etc/locale.gen
sed -i '82s/. //' /mnt/etc/sudoers
sed -i '33s/.//' /mnt/etc/pacman.conf && sed -i '36s/.//' /mnt/etc/pacman.conf && sed -i '37s/.//' /mnt/etc/pacman.conf && sed -i '37s/5/12/' /mnt/etc/pacman.conf && sed -i '93/.//' /mnt/etc/pacman.conf && sed -i '94/.//' /mnt/etc/pacman.conf
sed '1,/^#part2$/d' arch.sh > /mnt/part2.sh
chmod +x /mnt/part2.sh
arch-chroot /mnt ./part2.sh
exit 

#part2
locale-gen
bootctl install
timedatectl set-ntp true
timedatectl set-timezone Asia/Riyadh
pacman -S git wget zsh nvidia-settings neofetch openssh reflector 
useradd -m -G wheel -s /bin/zsh wael
git clone https://aur.archlinux.org/paru.git /usr/src/paru && chmod 777 /usr/src/paru
systemctl enable systemd-networkd
systemctl enable fstrim.timer  
systemctl enable sshd
passwd wael && passwd

