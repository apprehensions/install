#!/bin/bash
# these are literally made for me, please never use this unless you are wael

echo "root: "
read root
echo "host: "
read host
echo "hostname: "
read name
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

pacstrap /mnt linux linux-firmware linux-headers base base-devel intel-ucode btrfs-progs sof-firmware xf86-video-intel mesa zsh
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt bootctl install
cp -v -r root/etc/systemd /mnt/etc/
echo $name > /mnt/etc/hostname
echo > /mnt/etc/issue
echo "127.0.0.1 localhost" > /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 $name.localdomain $name" >> /etc/hosts
echo "wael ALL=(ALL) ALL" > /etc/sudoers.d/wael
echo "LANG=en_us.UTF-8" > /etc/locale.conf
echo "en_us.UTF-8 UTF-8" > /etc/locale.gen
echo ""boot" "rw cryptdevice=$root:croot:allow-discards root=/dev/mapper/croot rootflags=subvol=@"" >> /mnt/boot/refind_linux.conf
echo "blacklist elan_i2c" > /mnt/modprobe.d/blacklist.conf
arch-chroot /mnt mkinitcpio -P linux
arch-chroot /mnt timedatectl set-ntp true
arch-chroot /mnt timedatectl set-timezone Asia/Riyadh
arch-chroot /mnt useradd -m -s /bin/zsh wael
arch-chroot /mnt locale-gen
arch-chroot /mnt passwd wael
arch-chroot /mnt passwd

# https://github.com/Bugswriter/arch-linux-magic/blob/master/arch_install.sh
