#!/usr/bin/env bash
echo "root:$ROOTPASSWD" | chpasswd -R /mnt -c SHA512
