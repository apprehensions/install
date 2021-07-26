uuid_root=$(blkid -o value -s UUID $ROOT)

if [[ "$HOST" = lp-artix ]]; then
	grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id='GRUB'
	sed -i '13s/.//' /etc/default/grub
	sed -i "/GRUB_CMDLINE_LINUX_DEFAULT=/s/\"$/ slub_debug=P nowatchdog page_poison=1 loglevel=5 intel_iommu=igfx_off&/" /etc/default/grub
	sed -i "/GRUB_CMDLINE_LINUX=/s/\"$/cryptdevice=UUID=$uuid_root:kroot&/" /etc/default/grub
fi

if [[ "$HOST" = pc-artix ]]; then
	grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id='Artix Linux'
fi

grub-mkconfig -o /boot/grub/grub.cfg
