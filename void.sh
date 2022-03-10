#!/usr/bin/env bash
source vars.conf
set -xe

# strapping
REPO=https://mirror.fit.cvut.cz/voidlinux
ARCH=x86_64
XBPS_ARCH=$ARCH xbps-install -S -r /mnt -R "$REPO" \
  base-minimal linux-mainline btrfs-progs dosfstools \
  pciutils usbutils xtools iproute2 \
  ncurses file man man-pages libgcc gummiboot \
  man man-pages libgcc xtools iproute2 \
  bluez kbd dhcpcd dbus rtkit seatd \
  wget git zsh

# mount
mount --rbind /sys /mnt/sys && mount --make-rslave /mnt/sys
mount --rbind /dev /mnt/dev && mount --make-rslave /mnt/dev
mount --rbind /proc /mnt/proc && mount --make-rslave /mnt/proc

# doasedit + genfstab
curl https://gitlab.com/-/snippets/2232559/raw/main/bash -o /mnt/usr/bin/genfstab 
curl https://raw.githubusercontent.com/AN3223/scripts/master/doasedit -o /mnt/usr/bin/doasedit
chmod a+x /mnt/usr/bin/genfstab /mnt/usr/bin/doasedit
/mnt/usr/bin/genfstab -U /mnt >> /mnt/etc/fstab

# resolv, hostname, locale, blacklist watchdog, services
cp /etc/resolv.conf /mnt/etc/
echo "ephemera" > /mnt/etc/hostname
sed -i '/^#en_US.UTF-8/s/.//' /mnt/etc/default/libc-locales 
echo "blacklist iTCO_wdt" > /mnt/etc/modprobe.d/blacklist.conf
chroot /mnt ln -sfv /usr/share/zoneinfo/Asia/Riyadh /etc/localtime
chroot /mnt ln -sfv /etc/sv/dbus /etc/runit/runsvdir/default
chroot /mnt ln -sfv /etc/sv/rtkit /etc/runit/runsvdir/default
chroot /mnt ln -sfv /etc/sv/seatd /etc/runit/runsvdir/default
chroot /mnt ln -sfv /etc/sv/dhcpcd /etc/runit/runsvdir/default

# user, password, doas
groupadd -R /mnt plugdev
useradd -R /mnt -mG audio,video,kvm,input,bluetooth,_seatd,rtkit,plugdev -s /bin/zsh wael
echo "root:$USERPASSWD" | chpasswd -R /mnt -c SHA512
echo "wael:$ROOTPASSWD" | chpasswd -R /mnt -c SHA512
sed -i "/GETTY_ARGS=/s/\"$/ --autologin wael&/" /mnt/etc/sv/agetty-tty1/conf
cat > /mnt/etc/doas.conf << EOL
permit wael
permit persist wael
EOL

# repos, ucode, reconfigure, set mirrors
echo "kernel_cmdline=\" root=UUID=$(blkid $ROOT -s UUID -o value) rw quiet\"" > /mnt/etc/dracut.conf.d/cmdline
xbps-install -Sy -r /mnt -R $REPO void-repo-nonfree void-repo-multilib void-repo-multilib-nonfree
xbps-reconfigure -r /mnt -fa
chroot /mnt gummiboot install
echo "console-mode max" >> /mnt/boot/loader/loader.conf
mkdir -p /mnt/etc/xbps.d
cp /mnt/usr/share/xbps.d/*-repository-*.conf /mnt/etc/xbps.d/
sed -i "s|https://alpha.de.repo.voidlinux.org|$REPO|g" /mnt/etc/xbps.d/*-repository-*.conf


