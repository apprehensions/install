# locale
echo "LANG=en_US.UTF-8" > /etc/locale.con
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen

# time
ln -sf /usr/share/zoneinfo/Asia/Riyadh /etc/localtime

# pacman configuration
sed -i '33s/.//' /etc/pacman.conf
sed -i -e '37s/.//' -e '37s/5/64/' /etc/pacman.conf
sed -i '93,94s/.//' /etc/pacman.conf

# packages
pacman --noconfirm -Sy zsh terminus-font iwd 

# vconsole font
echo "FONT=ter-v18n" > /etc/vconsole.conf

# modular modulerer
echo "blacklist i2c_nvidia_gpu" > /etc/modprobe.d/i2c_nvidia_gpu.conf 
echo "blacklist iTCO_wdt" > /etc/modprobe.d/watchdog.conf 
mkinitcpio -P

# wireless, disabled to use only when necessary
mkdir -pv /etc/iwd
cat <<EOF > /etc/iwd/main.conf
[General]
UseDefaultInterface=true
EOF

# set wheel group to use sudo
sed -i '82s/. //' /etc/sudoers

# user add
useradd -mG wheel,audio,video -s /bin/zsh wael
passwd wael 

# automatica getty sign-in
mkdir /etc/systemd/system/getty@tty1.service.d
cat <<EOF > /etc/systemd/system/getty@tty1.service.d/override.conf 
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin wael --noclear %I \$TERM"
EOF
