echo "GRUB_ENABLE_CRYPTODISK=y" > /etc/default/grub
sed -i "/GRUB_CMDLINE_LINUX=/s/\"$/ cryptdevice=UUID=$(blkid -o value -s UUID $ROOT):kroot &/" /etc/default/grub
sed -i "/GRUB_CMDLINE_LINUX_DEFAULT=/s/\"$/ slub_debug=P page_poison=1 loglevel=5 intel_iommu=igfx_off&/" /etc/default/grub
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id='GRUB'
grub-mkconfig -o /boot/grub/grub.cfg
