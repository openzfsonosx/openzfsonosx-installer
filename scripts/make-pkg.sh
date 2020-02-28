#!/bin/bash -x

set -e

source version
owner=`logname`
dev_id_application="Developer ID Application: Joergen  Lundman (735AM5QEU3)"
dev_id_installer="Developer ID Installer: Joergen  Lundman (735AM5QEU3)"
keychain=`eval "echo ~${owner}"`/Library/Keychains/openzfs.keychain
#keychain_timeout=1200
keychain_timeout=none
should_unlock=1
should_sign_installer=1
require_version2_signature=1
spl_kernel_exports_kext="spl.kext/Contents/PlugIns/KernelExports.kext/"
spl_kext="spl.kext/"
zfs_kext="zfs.kext/"
os_release_major_version=`uname -r | awk -F '.' '{print $1;}'`
signargs="--options runtime"
notarize_1014=${notarize_1014:-1}

if [ $notarize_1014 -eq 1 ]
then
    if [ -z $NOTARIZE_PASS ]
    then
        echo "Set ENVVAR NOTARIZE_PASS for notarization to work."
        exit 1
    fi
fi

if [ -z $os_release_major_version ]
then
	echo "Could not determine operating system release major version"
	exit 1
fi

if [[ $1 == *1015* || $0 == *1015* || $PWD == *1015* ]]
then
	OS=1015
elif [[ $1 == *1014* || $0 == *1014* || $PWD == *1014* ]]
then
	OS=1014
elif [[ $1 == *1013* || $0 == *1013* || $PWD == *1013* ]]
then
	OS=1013
elif [[ $1 == *1012* || $0 == *1012* || $PWD == *1012* ]]
then
	OS=1012
elif [[ $1 == *1011* || $0 == *1011* || $PWD == *1011* ]]
then
	OS=1011
elif [[ $1 == *1010* || $0 == *1010* || $PWD == *1010* ]]
then
	OS=1010
elif [[ $1 == *9* || $0 == *9* || $PWD == *9* ]]
then
	OS=109
else
	OS=108
fi

if [ $require_version2_signature -eq 1 -a $os_release_major_version -lt 14 -a $OS -gt 108 ]
then
	echo "It is necessary to sign code while running OS X Mavericks or higher to get a version 2 signature."
	exit 1
fi

re='^[0-9]+$'
if ! [[ ${keychain_timeout} =~ $re ]]
then
	if [ x"${keychain_timeout}" != x"none" ]
	then
		echo "The keychain timeout should be a number or \"none\"" >&2
		exit 1
	fi
fi

if [ $(id -u) -ne 0 ]
then
	set +e
	echo "" | sudo -S echo "" &>/dev/null
	ret=$?
	set -e

	if [ $ret -ne 0 ]
	then
		echo "Please enter your login password"
		read -s loginpassword
		export LP="$loginpassword"
		#die if the password doesn't work
		set +e
		echo "$LP" | sudo -S echo "" &>/dev/null
		if [ $? -ne 0 ]
		then
			echo "incorrect login password"
			exit 1
		fi
	fi
fi

if [ $should_unlock -eq 1 ]
then
	set +e
	&>/dev/null security show-keychain-info "${keychain}"
	ret=$?
	if [ $ret -ne 0 -a x"$OZP" != x ]
	then
		security unlock-keychain -p "$OZP" "${keychain}"
		ret=$?
	fi
	set -e

	if [ $ret -ne 0 ]
	then
		security unlock-keychain "${keychain}"
	fi

	if [ x"${keychain_timeout}" = x -o "${keychain_timeout}" = "none" ]
	then
		security set-keychain-settings "${keychain}"
	else
		security set-keychain-settings -t "${keychain_timeout}" "${keychain}"
	fi
fi

if [ $(id -u) -ne 0 ]
then
	if [ x"$LP" != x ]
	then
		echo "$LP" | sudo -S -E "$0" "$@"
	else
		sudo -n -E "$0" "$@"
	fi
	exit $?
fi

cd packages-o3x-${OS}

if [ $os_release_major_version -ge 13 ]
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
if [ ${OS} -ge 109 ]
then
	pushd ${OS}/Library/Extensions &>/dev/null
	for path in "${spl_kernel_exports_kext}" "${spl_kext}" "${zfs_kext}"
	do
		set +e
		codesign -dvvv "${path}"
		ret=1
		set -e
		if [ $ret -ne 0 ]
		then
			echo "Signing ${path}"
			codesign $signargs -fvs "${dev_id_application}" "${path}"
			# spctl --assess --raw "${path}"
			codesign -dvvv "${path}"
		fi
	done
	popd

	# /usr -> /usr/local from 10.11 and up
	if [ ${OS} -lt 1011 ]; then
	    pushd ${OS}/usr/sbin &>/dev/null
	else
	    pushd ${OS}/usr/local/bin &>/dev/null
	fi

	for path in InvariantDisks fsck_zfs mount_zfs \
	    zconfigd zdb zdb_static zed zfs zfs_util zhack zinject zpios \
	    zpool zstreamdump zsysctl ztest ztest_static
	do
		set +e
		codesign -dvvv "${path}"
		ret=$?
		set -e
		if [ $ret -ne 0 ]
		then
			echo "Signing ${path}"
			codesign $signargs -fvs "${dev_id_application}" "${path}"
			# spctl --assess --raw "${path}"
			codesign -dvvv "${path}"
		fi
	done
	popd

	# /sbin -> /usr/local/bin from 10.11 and up
	if [ ${OS} -lt 1011 ]; then
	    pushd ${OS}/sbin &>/dev/null
	else
	    pushd ${OS}/usr/local/bin &>/dev/null
	fi

	for path in mount_zfs umount_zfs fsck_zfs
	do
		set +e
		codesign -dvvv "${path}"
		ret=$?
		set -e
		if [ $ret -ne 0 ]
		then
			echo "Signing ${path}"
			codesign $signargs -fvs "${dev_id_application}" "${path}"
			# spctl --assess --raw "${path}"
			codesign -dvvv "${path}"
		fi
	done
	popd

	# /usr -> /usr/local from 10.11 and up
	if [ ${OS} -lt 1011 ]; then
	    pushd ${OS}/usr/lib &>/dev/null
	else
	    pushd ${OS}/usr/local/lib &>/dev/null
	fi
	for path in *.dylib
	do
		set +e
		codesign -dvvv "${path}"
		ret=$?
		set -e
		if [ $ret -ne 0 ]
		then
			echo "Signing ${path}"
			codesign $signargs -fvs "${dev_id_application}" "${path}"
			# spctl --assess --raw "${path}"
			codesign -dvvv "${path}"
		fi
	done
	popd

	# /usr -> /usr/local from 10.11 and up
	if [ ${OS} -lt 1011 ]; then
	    pushd ${OS}/System/Library/Filesystems/zfs.fs/Contents/Resources &>/dev/null
	else
	    pushd ${OS}/Library/Filesystems/zfs.fs/Contents/Resources &>/dev/null
	fi

	for path in zfs_util mount_zfs fsck_zfs newfs_zfs
	do
		set +e
		codesign -dvvv "${path}"
		ret=$?
		set -e
		if [ $ret -ne 0 ]
		then
			echo "Signing ${path}"
			codesign $signargs -fvs "${dev_id_application}" "${path}"
			# spctl --assess --raw "${path}"
			codesign -dvvv "${path}"
		fi
	done
	popd
fi

echo "Creating pkg"
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
	productsign --sign "${dev_id_installer}" --keychain "${keychain}" out-${OS}.pkg out-${OS}-signed.pkg
	chown ${owner} out-${OS}-signed.pkg
	do_rsync out-${OS}-signed.pkg ../
	chown ${owner} ../out-${OS}-signed.pkg
else
	do_rsync out-${OS}.pkg ../
	chown ${owner} ../out-${OS}.pkg
fi

if [ ${notarize_1014} -eq 1 -a $OS -ge 1014 ]
then
    echo "Uploading PKG to Apple ..."
    TFILE="out-altool.xml"
    RFILE="req-altool.xml"
    xcrun altool --notarize-app -f ../out-${OS}-signed.pkg --primary-bundle-id net.lundman.zfs -u lundman@lundman.net -p "$NOTARIZE_PASS" --output-format xml > ${TFILE}

    GUID=`/usr/libexec/PlistBuddy -c "Print :notarization-upload:RequestUUID" ${TFILE}`
    echo "Uploaded. GUID ${GUID}"
    echo "Waiting for Apple to notarize..."
    while [ 1 ] 
    do
	sleep 10
	echo "Querying Apple."

	xcrun altool --notarization-info "${GUID}" -u lundman@lundman.net -p "$NOTARIZE_PASS" --output-format xml > ${RFILE}
	status=`/usr/libexec/PlistBuddy -c "Print :notarization-info:Status" ${RFILE}`
	if [ "$status" != "in progress" ]; then 
	    echo "Status: $status ."
	    break
	fi
	echo "Status: $status - sleeping ..."
	sleep 30
    done

    echo "Stapling PKG ..."
    xcrun stapler staple ../out-${OS}-signed.pkg
    xcrun stapler validate -v ../out-${OS}-signed.pkg
fi
