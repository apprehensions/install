echo "LANG=en_US.UTF-8" > /etc/locale.conf
sed -i '177s/.//' /etc/locale.gen
locale-gen
echo $HOSTNAME > /etc/hostname
ln -sf /usr/share/zoneinfo/Asia/Riyadh /etc/localtime
hwclock --systohc
