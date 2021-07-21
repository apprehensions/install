grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id='GRUB'

if [[ "$HOST" = lp-ao ]]; then
	sed -i '13s/.//' /etc/default/grub
	sed -i "/GRUB_CMDLINE_LINUX=/s/\"$/ cryptdevice=UUID=$(blkid -o value -s UUID $ROOT):kroot &/" /etc/default/grub
	sed -i "/GRUB_CMDLINE_LINUX_DEFAULT=/s/\"$/ slub_debug=P nowatchdog page_poison=1 loglevel=5 intel_iommu=igfx_off&/" /etc/default/grub
fi

grub-mkconfig -o /boot/grub/grub.cfg
