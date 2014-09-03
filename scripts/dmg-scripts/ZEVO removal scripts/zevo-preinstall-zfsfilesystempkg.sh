#! /bin/sh

#
# Uninstall previous extensions
#
uninstalled="/tmp/zfs-uninstalled-files.e8437/"

/bin/mkdir "/tmp/zfs-uninstalled-files.e8437"
/bin/mv -fv "/System/Library/Extensions/ZFSFilesystem.kext" "${uninstalled}"

exit 0