# pc
if [[ "$HOST" = "pc-as" ]] ; then
  systemctl enable systemd-networkd
fi

if [[ "$HOST" = "pc-ar" ]] ; then
	rc-service add service dhcpcd default
	rc-service add service sshd default
fi

# laptop
if [[ "$HOST" = "lp-ao" ]] ; then
	ln -sv /etc/runit/sv/dhcpcd /etc/runit/runsvdir/default/
	ln -sv /etc/runit/sv/iwd /etc/runit/runsvdir/default/
	rm -rf /etc/runit/runsvdir/default/elogind
fi

if [[ "$HOST" = "lp-ar" ]] ; then
	rc-service add service dhcpcd default
	rc-service add service iwd default
fi
