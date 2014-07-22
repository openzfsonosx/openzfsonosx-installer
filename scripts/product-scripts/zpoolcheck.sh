#!/bin/bash

#exit code 1 means no zfs file systems mounted

echo "Mounted ZFS file system(s) check"
/sbin/mount | awk -F '(' '{print $2;}' | awk -F ',' '{print $1;}' | grep zfs &>/dev/null

[ $? -eq 0 ] && exit 0

exit 1
