#!/bin/bash -x

set -e

if [[ $(id -u) -ne 0 ]]
then
        sudo "$0" "$@"
        exit 0
fi

version=1.3.0
owner=`logname`
dev_id_application="Developer ID Application: Joergen  Lundman (735AM5QEU3)"
dev_id_installer="Developer ID Installer: Joergen  Lundman (735AM5QEU3)"
keychain=`eval "echo ~${owner}"`/Library/Keychains/openzfs-login.keychain
should_unlock=1
should_sign_installer=1
zfs_kext="zfs.kext/"
spl_kext="spl.kext/"
spl_kernel_exports_kext="spl.kext/Contents/Plugins/KernelExports.kext/"

if [[ $1 == *8* || $0 == *8* || $PWD == *8* ]]
then
	OS=108
else
	OS=109
fi

cd packages-o3x-${OS}

if [ `uname -r | awk -F '.' '{ print $1; }'` -ge 13 ]
then
	productbuild_has_scripts_option=1
else
	productbuild_has_scripts_option=0
fi

if [ -e /usr/local/bin/rsync ]
then
	export RSYNC="/usr/local/bin/rsync"
	export RSYNC_OPTIONS="-rltDcAX --fileflags --itemize-changes"
else
	export RSYNC="/usr/bin/rsync"
	export RSYNC_OPTIONS="-rltDcE --itemize-changes"
fi

do_rsync() {
	"$RSYNC" $RSYNC_OPTIONS "$1" "$2"
}

do_unlock() {
	set +e
	&>/dev/null security show-keychain-info "${keychain}"
	ret=$?
	set -e
	[ $ret -ne 0 ] && security unlock-keychain "${keychain}"
	set +e
	&>/dev/null security show-keychain-info login.keychain
	ret=$?
	set -e
	[ $ret -ne 0 ] && security unlock-keychain login.keychain
	return 0
}

if [ ${OS} -ge 109 ]
then
	[ ${should_unlock} -eq 1 ] && do_unlock
	pushd ${OS}/Library/Extensions
	for path in "${zfs_kext}" "${spl_kernel_exports_kext}" "${spl_kext}"
	do
		set +e
		spctl --assess "${path}"
		ret=$?
		set -e
		if [ $ret -ne 0 ]
		then
			codesign -fvs "${dev_id_application}" "${path}"
			spctl --assess --raw "${path}"
		fi
	done
	popd
fi

sudo -u ${owner} packagesbuild -F . packages-o3x-${OS}.pkgproj

rm -rf conv ; mkdir conv
do_rsync build/OpenZFS\ on\ OS\ X.mpkg/Contents/ conv/

cd conv
mkdir Scripts
mv Resources/*.sh Scripts/
mv Packages/* ./
patch < ../distribution-dist-${OS}.patch

if [ ${productbuild_has_scripts_option} -eq 1 ]
then
	productbuild --version ${version} --distribution distribution.dist ../out-${OS}.pkg --resources Resources --scripts Scripts
	cd ..
else
	productbuild --version ${version} --distribution distribution.dist ../out-${OS}.pkg --resources Resources
	cd ..
	rm -rf ex-${OS}
	pkgutil --expand out-${OS}.pkg ex-${OS}
	rm out-${OS}.pkg
	mkdir ex-${OS}/Scripts
	do_rsync conv/Scripts/ ex-${OS}/Scripts/
	pkgutil --flatten ex-${OS} out-${OS}.pkg
fi

chown ${owner} out-${OS}.pkg
rm -rf ex-${OS}
sudo -u ${owner} pkgutil --expand out-${OS}.pkg ex-${OS}

rm -f ../out-${OS}.pkg
rm -f ../out-${OS}-signed.pkg

if [ ${should_sign_installer} -eq 1 ]
then
	[ ${should_unlock} -eq 1 ] && do_unlock
	productsign --sign "${dev_id_installer}" --keychain "${keychain}" out-${OS}.pkg out-${OS}-signed.pkg
	chown ${owner} out-${OS}-signed.pkg
	do_rsync out-${OS}-signed.pkg ../
	chown ${owner} ../out-${OS}-signed.pkg
else
	do_rsync out-${OS}.pkg ../
	chown ${owner} ../out-${OS}.pkg
fi
