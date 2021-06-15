#!/bin/bash
name=br

echo "root: "
read root
echo "esp: "
read esp
mkfs.btrfs -f $root
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
umount -R /mnt
mount -o compress=zstd,subvol=/@ /dev/mapper/croot /mnt
mkdir /mnt/home
mount -o compress=zstd,subvol=/@home /dev/mapper/croot /mnt
mkdir /mnt/boot
mount $esp /mnt/boot

pacstrap /mnt linux linux-firmware linux-headers base base-devel intel-ucode btrfs-progs nvidia zsh xorg xorg-xinit xclip zsh
genfstab -U /mnt >> /mnt/etc/fstab
cp -v -r root/etc /mnt
cp -v -r root/boot /mnt
echo $name > /mnt/etc/hostname
echo "127.0.0.1 localhost" > /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 $name.localdomain $name" >> /etc/hosts
echo "wael ALL=(ALL) ALL" > /etc/sudoers.d/wael
echo "LANG=en_us.UTF-8" > /etc/locale.conf
echo "en_us.UTF-8 UTF-8" > /etc/locale.gen
echo "title   Arch Linux"
echo "linux   /vmlinuz-linux" >> /mnt/boot/loader/entries/arch.conf
echo "initrd  /intel-ucode.img" >> /mnt/boot/loader/entries/arch.conf
echo "initrd  /initramfs-linux.img" > /mnt/boot/loader/entries/arch.conf
echo "options rw root=$root rootflags=subvol=@" >> /mnt/boot/loader/entries/arch.conf
# https://github.com/Bugswriter/arch-linux-magic/blob/master/arch_install.sh
sed '1,/^#part2$/d' arch_install.sh > /mnt/arch_install2.sh
chmod +x /mnt/arch_install2.sh
arch-chroot /mnt ./arch_install2.sh
exit 

#part2
bootctl install
timedatectl set-ntp true
timedatectl set-timezone Asia/Riyadh
useradd -m -s /bin/zsh wael
locale-gen
systemctl enable reflector.timer
systemctl enable fstrim.timer  
systemctl enable sshd
passwd wael
passwd
