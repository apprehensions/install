#!/usr/bin/env bash
source ../vars.conf
set -xe

chroot /mnt gummiboot install
