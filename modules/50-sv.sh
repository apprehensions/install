# pc

if [[ "$HOST" = "pc_art" ]] ; then
	rc-update add dhcpcd default
fi

if [[ "$HOST" = "pc_arch" ]]; then
	echo -e "[Match]\nName=eno1\n\n[Network]\nDHCP=yes" > /etc/systemd/network/lan.network
	systemctl enable systemd-networkd
fi

# laptop

if [[ "$HOST" = "lp_art" ]] ; then
	rc-update add dhcpcd default
	rc-update add iwd default
fi
