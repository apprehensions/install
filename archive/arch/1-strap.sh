reflector -a 48 -l 16 -f 6 --verbose --sort rate --save /etc/pacman.d/mirrorlist
sed -i -e '/^#Para/s/.//' -e '/^Para/s/5/64/' /etc/pacman.conf

pacstrap /mnt linux linux-firmware linux-headers base base-devel \
  btrfs-progs iwd intel-ucode git zsh terminus-font bat opendoas wget

cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/
genfstab -L /mnt >> /mnt/etc/fstab
