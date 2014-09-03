#! /bin/sh

#
# Uninstall previous drivers
#
uninstalled="/tmp/zfs-uninstalled-files.e8437/"

/bin/mkdir "/tmp/zfs-uninstalled-files.e8437"
/bin/mv -fv "/System/Library/Extensions/ZFSDriver.kext" "${uninstalled}"

exit 0