#!/bin/bash -x

if [[ $(id -u) -ne 0 ]]
then
	sudo "$0" "$@"
fi

READLINK=`which greadlink 2>/dev/null`
if test x$READLINK = "x" ; then
	READLINK=`which readlink 2>/dev/null`
fi

if ! test x$READLINK = "x" ; then
	$READLINK -f . > /dev/null 2>&1
	if ! test x$? = "x0" ; then
		unset READLINK
	else
		CANONICALIZE="$READLINK -f"
	fi
fi

if test x$READLINK = "x" ; then
	REALPATH=`which grealpath 2>/dev/null`
	if test x$REALPATH = "x" ; then
		REALPATH=`which realpath 2>/dev/null`
	fi
	if test x$REALPATH = "x" ; then
		CANONICALIZE=readlink
	else
		CANONICALIZE=$REALPATH
	fi
fi

topdir=`dirname "$($CANONICALIZE "$0")"`

if test x$topdir = x"." ; then
	if ! test -d resources -a -d scripts -a -f README.md ; then
		printf "cd into the zfs installer repository or install GNU readlink or realpath.\n"
		printf "Homebrew: brew install coreutils\n"
		printf "MacPorts: port install coreutils\n"
		printf "Gentoo Prefix: emerge sys-apps/coreutils\n"
		exit 1
	fi
fi

set -e

cd "${topdir}"

HOME_DIR="$(dscl . -read /Users/"$(logname)" NFSHomeDirectory | cut -d ' ' -f2)"

make_only=0

MLDEV="${HOME_DIR}"/Developer/mountainlion
MAVDEV="${HOME_DIR}"/Developer/mavericks

MLPAK="${topdir}"/packages-o3x-108
MLDESTDIR="${MLPAK}"/108

MAVPAK="${topdir}"/packages-o3x-109
MAVDESTDIR="${MAVPAK}"/109

if [ $make_only -eq 1 ]
then
	./scripts/zfsadm-for-installer.sh -t 10.8 -d "${MLDEV}" -i /System/Library/Extensions -m
	./scripts/zfsadm-for-installer.sh -t 10.9 -d "${MAVDEV}" -i /Library/Extensions -m
else
	./scripts/zfsadm-for-installer.sh -t 10.8 -d "${MLDEV}" -i /System/Library/Extensions
	./scripts/zfsadm-for-installer.sh -t 10.9 -d "${MAVDEV}" -i /Library/Extensions
fi

rm -rf "${MLDESTDIR}"
cd "${MLDEV}"

cd spl
sudo make DESTDIR="${MLDESTDIR}" install
cd ..

cd zfs
sudo make DESTDIR="${MLDESTDIR}" install
cd ..

rm -rf "${MAVDESTDIR}"
cd "${MAVDEV}"

cd spl
sudo make DESTDIR="${MAVDESTDIR}" install
cd ..

cd zfs
sudo make DESTDIR="${MAVDESTDIR}" install
cd ..

cd "${topdir}"
./scripts/make-pkg.sh 108
./scripts/make-pkg.sh 109
