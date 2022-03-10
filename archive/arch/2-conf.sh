echo $hostname > /mnt/hostname
echo "LANG=en_US.UTF-8" > /mnt/locale.conf
echo "en_US.UTF-8 UTF-8" > /mnt/locale.gen
echo "FONT=ter-v16n" > /mnt/vconsole.conf
echo "blacklist iTCO_wdt" > /mnt/modprobe.d/blacklist.conf

cat > /mnt/etc/systemd/network/ether.network << EOL
[Match]
Name=e*

[Network]
DHCP=yes
EOL

sed -i -e '/^#Col/s/.//' \
       -e '/^#Ver/s/.//' \
       -e '/^#Para/s/.//' \
       -e '/^Para/s/5/24/' \
       -e '/^#\[multilib\]/s/.//' \
       -e '94s/#//' /mnt/etc/pacman.conf

cat > /etc/doas.conf << EOL
permit wael
permit persist wael
permit nopass wael as root cmd dmesg
permit nopass wael as root cmd pacman
EOL
