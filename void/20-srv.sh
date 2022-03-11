#!/usr/bin/env bash
source ../vars.conf
set -xe

# for every service listed in VOID_SERVICES,
for sv in ${VOID_SERVICES[@]}; do
  # install service and enable it
  case $sv in
    # except bluetooth as its service name differs
    bluez)
      xbps-install -R /mnt bluez
      chroot /mnt ln -sfv /etc/sv/bluetoothd /etc/runit/runsvdir/default 
    ;;
    *)
      xbps-install -R /mnt $sv
      chroot /mnt ln -sfv /etc/sv/$sv /etc/runit/runsvdir/default 
    ;;
  esac
done
