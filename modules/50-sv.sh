# pc

if [[ "$HOST" = "pc-artix" ]] ; then
	rc-update add dhcpcd default
fi

# laptop

if [[ "$HOST" = "lp-artix" ]] ; then
	rc-update add dhcpcd default
	rc-update add iwd default
fi
