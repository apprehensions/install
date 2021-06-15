#!/bin/bash

echo "root: "
read root
name="yoga"
echo "esp: "
read esp

if [[ $HOST = laptop ]] ; then	
	cryptsetup luksFormat $ROOT
	cryptsetup open $ROOT croot
	mkfs.btrfs -f /dev/mapper/croot
	mount -o compress=zstd /dev/mapper/croot /mnt
	btrfs subvolume create /mnt/@
	btrfs subvolume create /mnt/@home
	umount -R /mnt
	mount -o compress=zstd,subvol=/@ /dev/mapper/croot /mnt
	mkdir /mnt/home
	mount -o compress=zstd,subvol=/@home /dev/mapper/croot /mnt
fi

read -p "esp format? [y/n]" answer
[ $answer = y ] && mkfs.vfat -F 32 $esp
mkdir /mnt/boot
mount $esp /mnt/boot

pacstrap /mnt linux linux-firmware linux-headers base base-devel intel-ucode btrfs-progs sof-firmware xf86-video-intel mesa zsh xorg xorg-xinit xclip iwd
genfstab -U /mnt >> /mnt/etc/fstab
cp -v -r root/etc /mnt/etc
echo $name > /mnt/etc/hostname
echo "127.0.0.1 localhost" > /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 $name.localdomain $name" >> /etc/hosts
echo "wael ALL=(ALL) ALL" > /etc/sudoers.d/wael
echo "LANG=en_us.UTF-8" > /etc/locale.conf
echo "en_us.UTF-8 UTF-8" > /etc/locale.gen
echo ""boot" "rw cryptdevice=$root:croot:allow-discards root=/dev/mapper/croot rootflags=subvol=@"" >> /mnt/boot/refind_linux.conf
echo "blacklist elan_i2c" > /mnt/modprobe.d/blacklist.conf

# https://github.com/Bugswriter/arch-linux-magic/blob/master/arch_install.sh
sed '1,/^#part2$/d' arch_install.sh > /mnt/arch_install2.sh
chmod +x /mnt/arch_install2.sh
arch-chroot /mnt ./arch_install2.sh
exit 

#part2
bootctl install
mkinitcpio -P linux
timedatectl set-ntp true
timedatectl set-timezone Asia/Riyadh
useradd -m -s /bin/zsh wael
locale-gen
systemctl enable reflector.timer
systemctl enable fstrim.timer  
systemctl enable sshd
passwd wael
passwd


