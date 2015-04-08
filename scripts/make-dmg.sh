#!/bin/bash

VERSION=1.3.1
PRETTY_108="OpenZFS on OS X $VERSION Mountain Lion.pkg"
PRETTY_109="OpenZFS on OS X $VERSION Mavericks or higher.pkg"
DMG_VOLNAME="OpenZFS on OS X $VERSION"

should_arrange=1
should_detach=0

if [ -e /usr/local/bin/rsync ]
then
        export RSYNC="/usr/local/bin/rsync"
        export RSYNC_OPTIONS="-rLtDcAX --fileflags --itemize-changes"
else
        export RSYNC="/usr/bin/rsync"
        export RSYNC_OPTIONS="-rLtDcE --itemize-changes"
fi

do_rsync() {
        "$RSYNC" $RSYNC_OPTIONS "$1" "$2"
}

hdiutil info | grep "$DMG_VOLNAME" &>/dev/null
ret=$?

if [ $ret -eq 0 ]
then
	dev="$( \
	    hdiutil info | \
	    grep "$DMG_VOLNAME" | \
	    head -1 | \
	    awk '{ print $1; }' \
	    )"
	hdiutil detach "$dev"
	hdiutil info | grep "$DMG_VOLNAME" &>/dev/null
	ret=$?
	if [ $ret -eq 0 ]
	then
		echo "Please detach the volume \"$DMG_VOLNAME\" before \
running this script."
		exit 1
	fi
fi

hdiutil info | grep "rw.dmg" &>/dev/null
ret=$?

if [ $ret -eq 0 ]
then
	echo "Please detach all instances of rw.dmg before running this script."
	exit 1
fi

rm -rf rw.*
rm -rf stage
mkdir -p "stage/.background"
mkdir -p "stage/Docs & Scripts/Docs"

do_rsync resources/dmg-background.png stage/.background/
do_rsync docs/ "stage/Docs & Scripts/Docs/"
do_rsync resources/English.lproj/ReadMe.rtf stage/
do_rsync Device\ Names.rtf stage/
do_rsync Unlinked\ Drain.rtf stage/
do_rsync Pool\ Upgrade.rtf stage/
do_rsync Memory\ Utilization.rtf stage/
do_rsync scripts/dmg-scripts/ "stage/Docs & Scripts/"

if [ -f out-108-signed.pkg ]
then
	do_rsync out-108-signed.pkg stage/"$PRETTY_108"
fi

if [ -f out-109-signed.pkg ]
then
	do_rsync out-109-signed.pkg stage/"$PRETTY_109"
fi

TMPDIR=$PWD
DMG_RW_TMPDIR=`mktemp -d -t rw`
rw_mntpoint="$( \
    hdiutil create \
    -size 40m \
    -fs HFS+J \
    -volname "$DMG_VOLNAME" \
    -attach \
    -plist \
    "$DMG_RW_TMPDIR"/rw.dmg | \
    xmllint --xpath "/plist/dict/array/dict/key[.='mount-point']/following-sibling::*[1]/text()" - \
    )"

do_rsync stage/ "$rw_mntpoint"/

if [ $should_arrange -eq 1 ]
then
	echo '
	on run argv
		tell application "Finder"
			tell disk (item 1 of argv)
				open
				set current view of container window to icon view
				set toolbar visible of container window to false
				set statusbar visible of container window to false
				set the bounds of container window to {400, 100, 850, 400}
				set viewOptions to the icon view options of container window
				set arrangement of viewOptions to not arranged
				set icon size of viewOptions to 72
				set background picture of viewOptions to file ".background:'dmg-background.png'"
				close
				open
				update without registering applications
				delay 2
			end tell
		end tell
	end run
' | osascript - "$(basename "$rw_mntpoint")"
fi

if [ $should_detach -eq 1 ]
then
	hdiutil detach "$rw_mntpoint"
fi

exit 0
