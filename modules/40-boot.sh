uuid_root=$(blkid -o value -s UUID $ROOT)

if [[ "$HOST" = lp_art ]]; then
	grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id='Artix Linux'
	sed -i "/GRUB_CMDLINE_LINUX_DEFAULT=/s/\"$/ slub_debug=P nowatchdog page_poison=1 loglevel=5&/" /etc/default/grub
fi

if [[ "$HOST" = pc_art ]]; then
	grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id='Artix Linux'
fi

echo -e "\nGRUB_DISABLE_OS_PROBER=false" /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
