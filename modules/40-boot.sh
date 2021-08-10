uuid_root=$(blkid -o value -s UUID $ROOT)

if [[ $DIST = artix ]]; then
	grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id='Artix Linux'
	sed -i "/GRUB_CMDLINE_LINUX_DEFAULT=/s/\"$/ nowatchdog loglevel=5&/" /etc/default/grub
	echo -e "\nGRUB_DISABLE_OS_PROBER=false" /etc/default/grub
	grub-mkconfig -o /boot/grub/grub.cfg
fi

if [[ $DIST = arch ]]; then
	echo -e "title   Arch Linux\nlinux   /vmlinuz-linux\ninitrd  /intel-ucode.img\ninitrd  /initramfs-linux.img" > /boot/loader/entries/arch.conf
	echo "options rw root=UUID=$uuid_root nowatchdog loglevel=5" >> /boot/loader/entries/arch.conf
	echo -e "timeout 5\nconsole-mode max" > /boot/loader/loader.conf
fi

