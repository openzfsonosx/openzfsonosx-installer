#!/bin/bash
if [[ $(id -u) -ne 0 ]]; then
echo "Please enter your password"
    sudo "$0" "$@"
    exit
fi

set +e

rm -rf /Library/Extensions/spl.kext
rm -rf /System/Library/Extensions/spl.kext
rm -rf /usr/src/spl-*
rm -rf /Library/Extensions/zfs.kext
rm -rf /System/Library/Extensions/zfs.kext
rm -rf /usr/src/zfs-*
rm -rf /usr/lib/modules-load.d
rm -rf /usr/lib/systemd
rm -rf /usr/local/etc/init.d
rm -rf /etc/init.d
rm -rf /usr/local/etc/zfs/
rm -rf /usr/local/include/libspl
rm -rf /usr/local/include/libzfs
rm -rf /usr/include/libspl
rm -rf /usr/include/libzfs
rm -rf /usr/local/lib/dracut
rm -rf /usr/lib/dracut
rm -rf /usr/local/lib/udev
rm -rf /usr/lib/udev
rm -rf /usr/local/share/zfs
rm -rf /usr/share/zfs
rm -rf /usr/libexec/zfs

rm -f /usr/local/share/man/man1/zhack.1
rm -f /usr/local/share/man/man1/zpios.1
rm -f /usr/local/share/man/man1/ztest.1
rm -f /usr/local/share/man/man5/vdev_id.conf.5
rm -f /usr/local/share/man/man5/zfs-module-parameters.5
rm -f /usr/local/share/man/man5/zpool-features.5
rm -f /usr/local/share/man/man8/fsck.zfs.8
rm -f /usr/local/share/man/man8/mount.zfs.8
rm -f /usr/local/share/man/man8/vdev_id.8
rm -f /usr/local/share/man/man8/zdb.8
rm -f /usr/local/share/man/man8/zfs.8
rm -f /usr/local/share/man/man8/zinject.8
rm -f /usr/local/share/man/man8/zpool.8
rm -f /usr/local/share/man/man8/zstreamdump.8
rm -f /usr/share/man/man1/zhack.1
rm -f /usr/share/man/man1/zpios.1
rm -f /usr/share/man/man1/ztest.1
rm -f /usr/share/man/man5/vdev_id.conf.5
rm -f /usr/share/man/man5/zfs-module-parameters.5
rm -f /usr/share/man/man5/zpool-features.5
rm -f /usr/share/man/man8/fsck.zfs.8
rm -f /usr/share/man/man8/mount.zfs.8
rm -f /usr/share/man/man8/vdev_id.8
rm -f /usr/share/man/man8/zdb.8
rm -f /usr/share/man/man8/zed.8
rm -f /usr/share/man/man8/zfs.8
rm -f /usr/share/man/man8/zinject.8
rm -f /usr/share/man/man8/zpool.8
rm -f /usr/share/man/man8/zstreamdump.8

rm -f /usr/local/lib/libnvpair.1.dylib
rm -f /usr/local/lib/libnvpair.a
rm -f /usr/local/lib/libnvpair.dylib
rm -f /usr/local/lib/libnvpair.la
rm -f /usr/local/lib/libuutil.1.dylib
rm -f /usr/local/lib/libuutil.a
rm -f /usr/local/lib/libuutil.dylib
rm -f /usr/local/lib/libuutil.la
rm -f /usr/local/lib/libzfs.2.dylib
rm -f /usr/local/lib/libzfs.a
rm -f /usr/local/lib/libzfs.dylib
rm -f /usr/local/lib/libzfs.la
rm -f /usr/local/lib/libzfs_core.1.dylib
rm -f /usr/local/lib/libzfs_core.a
rm -f /usr/local/lib/libzfs_core.dylib
rm -f /usr/local/lib/libzfs_core.la
rm -f /usr/local/lib/libzpool.1.dylib
rm -f /usr/local/lib/libzpool.a
rm -f /usr/local/lib/libzpool.dylib
rm -f /usr/local/lib/libzpool.la
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

rm -f /usr/local/bin/arcstat.pl
rm -f /usr/local/sbin/InvariantDisks
rm -f /usr/local/sbin/zdb
rm -f /usr/local/sbin/zdb_static
rm -f /usr/local/sbin/zed
rm -f /usr/local/sbin/zfs
rm -f /usr/local/sbin/zhack
rm -f /usr/local/sbin/zinject
rm -f /usr/local/sbin/zpios
rm -f /usr/local/sbin/zpool
rm -f /usr/local/sbin/zstreamdump
rm -f /usr/local/sbin/ztest
rm -f /usr/local/sbin/ztest_static
rm -f /usr/bin/arcstat.pl
rm -f /usr/sbin/InvariantDisks
rm -f /usr/sbin/zdb
rm -f /usr/sbin/zdb_static
rm -f /usr/sbin/zed
rm -f /usr/sbin/zfs
rm -f /usr/sbin/zhack
rm -f /usr/sbin/zinject
rm -f /usr/sbin/zpios
rm -f /usr/sbin/zpool
rm -f /usr/sbin/zstreamdump
rm -f /usr/sbin/ztest
rm -f /usr/sbin/ztest_static

rm -f /sbin/mount.zfs
rm -f /sbin/mount_zfs
rm -f /sbin/umount_zfs

rm -f /etc/zfs/vdev_id.conf.alias.example
rm -f /etc/zfs/vdev_id.conf.multipath.example
rm -f /etc/zfs/vdev_id.conf.sas_direct.example
rm -f /etc/zfs/vdev_id.conf.sas_switch.example

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

rm -f /Library/LaunchDaemons/org.openzfsonosx.InvariantDisks.plist
rm -f /Library/LaunchDaemons/org.openzfsonosx.zed.plist
rm -f /Library/LaunchDaemons/org.openzfsonosx.zed.service.plist
rm -f /Library/LaunchDaemons/org.openzfsonosx.zpool-autoimport.plist
rm -f /Library/LaunchDaemons/org.openzfsonosx.zpool-import-all.plist

rm -rf /System/Library/Filesystems/zfs.fs

rm -f /etc/zfs/zpool.cache
rm -f /etc/zfs/zpool.cache.tmp

[ -d  /etc/zfs/zed.d ] && [ $(ls -A /etc/zfs/zed.d | wc -l) -eq 0 ] && rmdir /etc/zfs/zed.d
[ -d  /etc/zfs ] && [ $(ls -A /etc/zfs | wc -l) -eq 0 ] && rmdir /etc/zfs
