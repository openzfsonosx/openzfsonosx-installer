#!/bin/bash

XCODE=/Applications/Xcode.app
SDKS="${XCODE}"/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs
SYSVER=System/Library/CoreServices/SystemVersion.plist

pbv() {
	/usr/libexec/PlistBuddy -c "Print :ProductBuildVersion" "$1"
}

if [ x"$1" = x"108" ]
then
	pbv "${SDKS}"/MacOSX10.8.sdk/"${SYSVER}"
elif [ x"$1" = x"109" ]
then
	pbv "${SDKS}"/MacOSX10.9.sdk/"${SYSVER}"
elif [ x"$1" = x"1010" ]
then
	pbv "${SDKS}"/MacOSX10.10.sdk/"${SYSVER}"
fi
