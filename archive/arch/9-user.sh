useradd -R /mnt -mG audio,video,input,kvm -s /bin/zsh wael
echo "root:$PASSWD" | chpasswd -R /mnt -c SHA512
echo "wael:$UPASSWD" | chpasswd -R /mnt -c SHA512
