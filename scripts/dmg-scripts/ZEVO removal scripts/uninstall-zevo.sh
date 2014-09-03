#!/bin/bash
set -e

TMPF=`mktemp /private/tmp/zfsinstaller-removezevo.XXXXXX`

echo "Checking for ZEVO"
set +e
pkgutil --pkgs | 1>/dev/null 2>/dev/null grep com.getgreenbytes.zfs
hasgreenbyteszfs=$?
pkgutil --pkgs | 1>/dev/null 2>/dev/null grep com.tenscomplement.zfs
hastenscomplementzfs=$?
set -e

if [ $hasgreenbyteszfs -eq 0 -o $hastenscomplementzfs -eq 0 ] ; then
	echo "Found ZEVO. Running ZEVO uninstaller."
	set +e
	sudo ./zevo-preinstall-zfspkg.sh
	sudo ./zevo-preinstall-zfsfilesystempkg.sh
	sudo ./zevo-preinstall-zfsdriverpkg.sh
	set -e
else
	echo "Did not find ZEVO."
fi
