# pc
if [[ "$HOST" = "pc-as" ]] ; then
  systemctl enable systemd-networkd
fi

if [[ "$HOST" = "pc-ao" ]] ; then
	rc-service add service dhcpcd default
fi

# laptop
if [[ "$HOST" = "lp-ar" ]] ; then
	ln -sv /etc/runit/sv/dhcpcd /etc/runit/runsvdir/default/
	ln -sv /etc/runit/sv/iwd /etc/runit/runsvdir/default/
	rm -rf /etc/runit/runsvdir/default/elogind
fi

if [[ "$HOST" = "lp-ao" ]] ; then
	rc-service add service dhcpcd default
	rc-service add service iwd default
fi
