#! /bin/sh

#
# Uninstall prior versions
#

sysbin="/usr/sbin/"
localbin="/usr/local/bin/"
launchd="/Library/LaunchDaemons/"
launchagents="/Library/LaunchAgents/"
prefpanes="/Library/PreferencePanes/"
uninstalled="/tmp/zfs-uninstalled-files.e8437/"

#
# first move any legacy files out of the way
#
/bin/rm -frv "/tmp/zfs-uninstalled-files.e8437"
/bin/mkdir "/tmp/zfs-uninstalled-files.e8437"

/bin/mv -fv "/usr/local/bin/ztest" "${uninstalled}"
/bin/mv -fv "/usr/local/bin/zoink" "${uninstalled}"
/bin/mv -fv "/usr/sbin/zfs" "${uninstalled}"
/bin/mv -fv "/usr/sbin/zpool" "${uninstalled}"
/bin/mv -fv "/usr/sbin/zdb" "${uninstalled}"
/bin/mv -fv "/usr/sbin/zoink" "${uninstalled}"
/bin/mv -fv "/usr/sbin/mount_zfs" "${uninstalled}"
/bin/mv -fv "/usr/lib/libzfs.dylib" "${uninstalled}"
/bin/mv -fv "/usr/lib/libzpool.dylib" "${uninstalled}"
/bin/mv -fv "/usr/share/man/man8/zfs.8" "${uninstalled}"
/bin/mv -fv "/usr/share/man/man8/zfs.util.8" "${uninstalled}"
/bin/mv -fv "/usr/share/man/man8/zpool.8" "${uninstalled}"

/bin/mv -fv "/etc/zfs" "${uninstalled}"etc-zfs
/bin/mv -fv "/System/Library/Filesystems/zfs.fs" "${uninstalled}"

#
# remove symlinks
#
/bin/rm -fv "${sysbin}"zfs
/bin/rm -fv "${sysbin}"zpool

/bin/rm -fv "${localbin}"zdb
/bin/rm -fv "${localbin}"ziltest
/bin/rm -fv "${localbin}"zinject
/bin/rm -fv "${localbin}"zstat
/bin/rm -fv "${localbin}"zstreamdump
/bin/rm -fv "${localbin}"ztest

#/bin/rm -fv "${launchd}"com.getgreenbytes.zfs.autopoolscrubs.plist
#/bin/rm -fv "${launchd}"com.getgreenbytes.zfs.autosnapshots.plist

/bin/rm -fv "${launchd}"com.tenscomplement.zfs.delegate.plist
/bin/rm -fv "${launchd}"com.tenscomplement.zfs.loader.plist
/bin/rm -fv "${launchagents}"com.tenscomplement.zfs.notifier.plist

/bin/rm -fv "${launchd}"com.getgreenbytes.zfs.delegate.plist
/bin/rm -fv "${launchd}"com.getgreenbytes.zfs.loader.plist
/bin/rm -fv "${launchagents}"com.getgreenbytes.zfs.notifier.plist

/bin/rm -frv "${prefpanes}"ZEVO.prefPane
/bin/rm -frv "${prefpanes}"ZEVOBeta.prefPane
/bin/rm -frv "${prefpanes}"ZEVOCommunity.prefPane
/bin/rm -frv "${prefpanes}"ZevoSilverPreferences.prefPane

exit 0