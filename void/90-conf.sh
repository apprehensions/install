#!/usr/bin/env bash
source ../vars.conf
set -xe

# set nostname
echo "$HOSTNAMESTRAP" > /mnt/etc/hostname

# locale (gnu)
sed -i '/^#en_US.UTF-8/s/.//' /mnt/etc/default/libc-locales

# dracut
cat > /mnt/etc/dracut.conf.d/options.conf << EOCONF
hostonly="yes"
hostonly_cmdline="yes"
compress="lz4"
add_drivers+=" usbhid "
omit_drivers+=" iTCO_wdt "
EOCONF

# gummiboot
echo -e "console-mode max\ntimeout 5" >> /mnt/boot/loader/loader.conf

