echo $HOSTNAME > /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts 
echo "127.0.1.1 $HOSTNAME.localdomain $HOSTNAME" >> /etc/hosts
# echo -e "nameserver 1.1.1.1\nnameserver 1.0.0.1" >> /etc/resolv.conf

