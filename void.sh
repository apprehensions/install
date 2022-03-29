#!/usr/bin/env bash
source ../../vars.conf
set -xe

XBPS_ARCH=$ARCH xbps-install -S -r /mnt -R "$REPO/current" ${VOID_PACKAGES[@]}

# disk
mount --rbind /sys /mnt/sys && mount --make-rslave /mnt/sys
mount --rbind /dev /mnt/dev && mount --make-rslave /mnt/dev
mount --rbind /proc /mnt/proc && mount --make-rslave /mnt/proc
curl https://gitlab.com/-/snippets/2232559/raw/main/bash -o /mnt/usr/bin/genfstab
chmod +x /mnt/usr/bin/genfstab
/mnt/usr/bin/genfstab -U /mnt >> /mnt/etc/fstab

# services
chroot /mnt ln -sfv /etc/sv/bluetoothd /etc/runit/runsvdir/default
chroot /mnt ln -sfv /etc/sv/{acpid,dbus,dhcpcd,rtkit} /etc/runit/runsvdir/default

# user
useradd -R /mnt -mG $USER_GROUPS -s /bin/zsh wael
sed -i '/^#en_US.UTF-8/s/.//' /mnt/etc/default/libc-locales
echo "wael:$USERPASSWD" | chpasswd -R /mnt -c SHA512
echo "root:$ROOTPASSWD" | chpasswd -R /mnt -c SHA512
echo "$HOSTNAMESTRAP" > /mnt/etc/hostname
sed -i "/GETTY_ARGS=/s/\"$/ --autologin wael&/" /mnt/etc/sv/agetty-tty1/conf
xbps-install -R /mnt opendoas
cat > /mnt/etc/doas.conf << EOCONF
permit wael
permit persist wael
EOCONF

# other
chroot /mnt gummiboot install
cat > /mnt/etc/dracut.conf.d/options.conf << EOCONF
hostonly="yes"
hostonly_cmdline="yes"
use_fstab=yes
show_modules="yes"
compress="cat"
omit_drivers+=" iTCO_wdt "
omit_drivers+=" nouveau "
omit_dracutmodules+=" bash terminfo "
nofscks=yes
EOCONF

cat > /mnt/usr/bin/splash << EOSPLSH
#!/bin/sh
tput reset
tput cup 9999 0

echo 'q' | fbv -ice /etc/splash.png
EOSPLSH
chmod +x /mnt/usr/bin/splash
echo '/usr/bin/splash' >> /mnt/etc/runit/core-services/03-console-setup.sh 

cat > /mnt/etc/rc.conf << EORCCONF
# /etc/rc.conf - system configuration for void

# Set the host name.
HOSTNAME="$HOSTNAMESTRAP"

# Set RTC to UTC or localtime.
HARDWARECLOCK="UTC"

# Set timezone, availables timezones can be found at /usr/share/zoneinfo.
TIMEZONE="Asia/Riyadh"

# Keymap to load, see loadkeys(8).
KEYMAP="us"

# Fonts, see setfont(8).
FONT="ter-v12n"
#FONT_MAP=
#FONT_UNIMAP=

# Amount of ttys which should be setup.
#TTYS=

# Set the mode for cgroup mounts.
# hybrid: mount cgroup v1 under /sys/fs/cgroup and
#         cgroup v2 under /sys/fs/cgroup/unified
# legacy: mount cgroup v1 /sys/fs/cgroup
# unified: mount cgroup v2 under /sys/fs/cgroup
CGROUP_MODE=hybrid
EORCCONF

# xbps
xbps-install -Sy -r /mnt -R $REPO/current void-repo-{multilib{,-nonfree},nonfree}
mkdir -p /mnt/etc/xbps.d
cp /mnt/usr/share/xbps.d/*-repository-*.conf /mnt/etc/xbps.d/
sed -i "s|https://alpha.de.repo.voidlinux.org|$REPO|g" /mnt/etc/xbps.d/*-repository-*.conf
xbps-reconfigure -r /mnt -fa
xbps-install -Syuv -r /mnt
