[ $HOST = lp-ao ] && sed -i "/GETTY_ARGS=/s/\"$/ --autologin wael&/" /etc/runit/sv/agetty-tty1/conf
