#!/bin/bash
set -e
echo "Checking for admin privileges"
if [[ $(id -u) -ne 0 ]]; then
set -e
echo "Please enter your password"
    sudo "$0" "$@"
    exit
fi
set -e
ULOG=`mktemp "$HOME"/zfsuninstaller.XXXXXX`
date >> "$ULOG"
echo "Starting uninstall" | tee -a "$ULOG"
echo "Created uninstall log file...$ULOG" | tee -a "$ULOG"
chmod 777 "$ULOG"
echo "No pools should be imported" | tee -a "$ULOG"

if [ -c /dev/zfs ] ; then
	if [ -e /usr/sbin/zpool ] ; then
		echo "Checking output of /usr/sbin/zpool status" | tee -a "$ULOG"
		TMPF=`mktemp /private/tmp/zfsuninstaller-zpoolcheck.XXXXXX`
		set +e
		2>>"$TMPF" 1>>"$TMPF" /usr/sbin/zpool status
		err=$?
		set -e
		zpoolstatuslinecount=$(cat "$TMPF" | wc -l | tr -d ' ')
		if [ "$zpoolstatuslinecount" -gt 1 -o "$err" -ne 0 ] ; then
			cat "$TMPF" | tee -a "$ULOG"
			echo ""
			echo "First export all pools" | tee -a "$ULOG"
			echo "Exiting uninstaller" | tee -a "$ULOG"
			echo "Uninstaller log is at $ULOG"
			exit 1
		fi
		rm "$TMPF"
	else
		echo "/usr/sbin/zpool does not exist." | tee -a "$ULOG"
		echo "You will need to export your pool(s) and unload zfs.kext manually before uninstalling." | tee -a "$ULOG"
		exit 1
	fi

	if [ -e /usr/sbin/zfs ] ; then
		echo "Checking output of /usr/sbin/zfs get name" | tee -a "$ULOG"
		TMPF=`mktemp /private/tmp/zfsuninstaller-zfscheck.XXXXXX`
		set +e
		2>>"$TMPF" 1>>"$TMPF" /usr/sbin/zfs get name 
		err=$?
		set -e
		zfsgetnamelinecount=$(cat "$TMPF" | wc -l)
		if [ "$zfsgetnamelinecount" -gt 0 ] ; then
			cat "$TMPF" | tee -a "$ULOG"
			echo ""
			echo "First export all pools" | tee -a "$ULOG"
			echo "Exiting uninstaller" | tee -a "$ULOG"
			echo "Uninstaller log is at $ULOG"
			exit 1
		fi
		rm "$TMPF"
	else
		echo "/usr/sbin/zfs does not exist." | tee -a "$ULOG"
		echo "You will need to export your pool(s) and unload zfs.kext manually before uninstalling." | tee -a "$ULOG"
		exit 1
	fi
fi

echo "Checking if zfs.kext is loaded" | tee -a $ULOG
if [ $(/usr/sbin/kextstat -b net.lundman.zfs | wc -l) -gt 1 ] ; then
	echo "zfs.kext is loaded" | tee -a "$ULOG"
	echo "Unloading zfs.kext" | tee -a "$ULOG"
set +e
   	sudo /sbin/kextunload -b net.lundman.zfs
	err=$?
set -e
	if [ "$err" -eq 0 ] ; then
		echo "zfs.kext was unloaded" | tee -a "$ULOG"
	else
		echo "zfs.kext failed to unload with error code $err" | tee -a "$ULOG"
		echo "Exiting uninstaller" | tee -a "$ULOG"
		echo "Uninstaller log is at $ULOG"
		exit 1
	fi
fi
echo "Checking if spl.kext is loaded" | tee -a "$ULOG"
if [ $(/usr/sbin/kextstat -b net.lundman.spl | wc -l) -gt 1 ] ; then
	echo "spl.kext is loaded" | tee -a "$ULOG"
	echo "Unloading spl.kext" | tee -a "$ULOG"
set +e
	sudo /sbin/kextunload -b net.lundman.spl
	err=$?
set -e
	if [ "$err" -eq 0 ] ; then
		echo "spl.kext was unloaded" | tee -a "$ULOG"
	else
		echo "spl.kext failed to unload with error code $err" | tee -a "$ULOG"
		echo "Exiting uninstaller" | tee -a "$ULOG"
		echo "Uninstaller log is at $ULOG"
		exit 1
	fi
fi

set +e
pgrep zed 1>/dev/null
pgrepret=$?
set -e
if [ $pgrepret -eq 0 ] ; then
	echo "Killing zed" | tee -a "$ULOG"
	killall zed
else
	echo "zed already stopped" | tee -a "$ULOG"
fi

echo "Removing launchd jobs" | tee -a "$ULOG"

set +e
launchctl list | grep org.openzfsonosx.InvariantDisks 1>/dev/null
grepret=$?
set -e
[ $grepret -eq 0 ] && /bin/launchctl remove org.openzfsonosx.InvariantDisks

set +e
launchctl list | grep org.openzfsonosx.zconfigd 1>/dev/null
grepret2=$?
set -e
[ $grepret2 -eq 0 ] && /bin/launchctl remove org.openzfsonosx.zconfigd

set +e
launchctl list | grep org.openzfsonosx.zed 1>/dev/null
grepret3=$?
set -e
[ $grepret3 -eq 0 ] && /bin/launchctl remove org.openzfsonosx.zed

set +e
launchctl list | grep org.openzfsonosx.zed.service 1>/dev/null
grepret4=$?
set -e
[ $grepret4 -eq 0 ] && /bin/launchctl remove org.openzfsonosx.zed.service

set +e
launchctl list | grep org.openzfsonosx.zpool-autoimport 1>/dev/null
grepret5=$?
set -e
[ $grepret5 -eq 0 ] && /bin/launchctl remove org.openzfsonosx.zpool-autoimport

set +e
launchctl list | grep org.openzfsonosx.zpool-import-all 1>/dev/null
grepret6=$?
set -e
[ $grepret6 -eq 0 ] && /bin/launchctl remove org.openzfsonosx.zpool-import-all

echo "Deleting installed files" | tee -a "$ULOG"
echo "Removing spl.kext" | tee -a "$ULOG"
rm -rfv /System/Library/Extensions/spl.kext
rm -rfv /Library/Extensions/spl.kext
echo "Removing zfs.kext" | tee -a "$ULOG"
rm -rfv /System/Library/Extensions/zfs.kext
rm -rfv /Library/Extensions/zfs.kext
echo "Removing zfs userland from /Library/OpenZFSonOSX" | tee -a "$ULOG"
rm -rfv /Library/OpenZFSonOSX/ZFSCommandLineTools
if [ -d /Library/OpenZFSonOSX ] ; then 
	if [ "$(ls -1 /Library/OpenZFSonOSX/ | wc -l)" -le 1 ] ; then
		[ -f /Library/OpenZFSonOSX/.DS_Store ] && rm /Library/OpenZFSonOSX/.DS_Store
		if [ "$(ls -1 /Library/OpenZFSonOSX/ | wc -l)" -eq 0 ] ; then
			rmdir /Library/OpenZFSonOSX
		fi
	fi
fi


echo "Removing zfs commands from /usr/sbin" | tee -a "$ULOG"
for c in InvariantDisks zdb zed zfs zinject zpool ztest zhack zpios zstreamdump; do
	rm -fv /usr/sbin/${c}
done

echo "Removing zfs libraries from /usr/lib" | tee -a "$ULOG"
rm -f /usr/lib/libnvpair.1.dylib
rm -f /usr/lib/libnvpair.a
rm -f /usr/lib/libnvpair.dylib
rm -f /usr/lib/libnvpair.la
rm -f /usr/lib/libuutil.1.dylib
rm -f /usr/lib/libuutil.a
rm -f /usr/lib/libuutil.dylib
rm -f /usr/lib/libuutil.la
rm -f /usr/lib/libzfs.2.dylib
rm -f /usr/lib/libzfs.a
rm -f /usr/lib/libzfs.dylib
rm -f /usr/lib/libzfs.la
rm -f /usr/lib/libzfs_core.1.dylib
rm -f /usr/lib/libzfs_core.a
rm -f /usr/lib/libzfs_core.dylib
rm -f /usr/lib/libzfs_core.la
rm -f /usr/lib/libzpool.1.dylib
rm -f /usr/lib/libzpool.a
rm -f /usr/lib/libzpool.dylib
rm -f /usr/lib/libzpool.la

echo "Removing arcstat.pl from /usr/bin" | tee -a "$ULOG"
rm -fv /usr/bin/arcstat.pl

echo "Removing mount_zfs and umount_zfs from /sbin" | tee -a "$ULOG"
rm -f /sbin/mount_zfs
rm -f /sbin/umount_zfs

echo "Removing man pages" | tee -a "$ULOG"
rm -f /usr/share/man/man1/zhack.1
rm -f /usr/share/man/man1/zpios.1
rm -f /usr/share/man/man1/ztest.1
rm -f /usr/share/man/man5/zpool-features.5
rm -f /usr/share/man/man8/zdb.8
rm -f /usr/share/man/man8/zed.8
rm -f /usr/share/man/man8/zfs.8
rm -f /usr/share/man/man8/zinject.8
rm -f /usr/share/man/man8/zpool.8
rm -f /usr/share/man/man8/zstreamdump.8

echo "Removing /etc/zfs/zed.d" | tee -a "$ULOG"
rm -f /etc/zfs/zed.d/all-debug.sh
rm -f /etc/zfs/zed.d/all-syslog.sh
rm -f /etc/zfs/zed.d/checksum-email.sh
rm -f /etc/zfs/zed.d/checksum-spare.sh
rm -f /etc/zfs/zed.d/config.remove.sh
rm -f /etc/zfs/zed.d/config.sync.sh
rm -f /etc/zfs/zed.d/data-email.sh
rm -f /etc/zfs/zed.d/generic-email.sh
rm -f /etc/zfs/zed.d/io-email.sh
rm -f /etc/zfs/zed.d/io-spare.sh
rm -f /etc/zfs/zed.d/resilver.finish-email.sh
rm -f /etc/zfs/zed.d/scrub.finish-email.sh
rm -f /etc/zfs/zed.d/snapshot.mount.sh
rm -f /etc/zfs/zed.d/zed.rc
rm -f /etc/zfs/zed.d/zpool.destroy.sh
rm -f /etc/zfs/zed.d/zpool.import.sh
rm -f /etc/zfs/zed.d/zvol.create.sh
rm -f /etc/zfs/zed.d/zvol.remove.sh
[ -d  /etc/zfs/zed.d ] && [ $(ls -A /etc/zfs/zed.d | wc -l) -eq 0 ] && rmdir /etc/zfs/zed.d

rm -f /etc/zfs/zpool.cache.tmp
rm -f /etc/zfs/zpool.cache
rm -f /etc/zfs/vdev_id.conf.alias.example
rm -f /etc/zfs/vdev_id.conf.sas_direct.example
rm -f /etc/zfs/vdev_id.conf.multipath.example
rm -f /etc/zfs/vdev_id.conf.sas_switch.example
rm -f /etc/zfs/zsysctl.conf.example
[ -d  /etc/zfs ] && [ $(ls -A /etc/zfs | wc -l) -eq 0 ] && rmdir /etc/zfs

echo "Removing /usr/libexec/zfs" | tee -a "$ULOG"
rm -rf /usr/libexec/zfs

echo "Removing launchd plists" | tee -a "$ULOG"
rm -f /Library/LaunchDaemons/org.openzfsonosx.InvariantDisks.plist
rm -f /Library/LaunchDaemons/org.openzfsonosx.zconfigd.plist
rm -f /Library/LaunchDaemons/org.openzfsonosx.zed.plist
rm -f /Library/LaunchDaemons/org.openzfsonosx.zed.service.plist
rm -f /Library/LaunchDaemons/org.openzfsonosx.zpool-autoimport.plist
rm -f /Library/LaunchDaemons/org.openzfsonosx.zpool-import-all.plist

echo "Removing zfs.fs" | tee -a "$ULOG"
rm -rf /System/Library/Filesystems/zfs.fs

echo "Telling OS X to forget zfs packages" | tee -a "$ULOG"
pkgutil --pkgs | grep net | grep lundman | while read p ; do echo "Forgetting $p" ; pkgutil --forget "$p" ; done

echo "Exiting uninstaller" | tee -a "$ULOG"
echo "Uninstaller log is at $ULOG"
