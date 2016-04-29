#!/bin/bash

source "$PWD"/version

APPDMG=/usr/local/bin/appdmg
JSON_PATH="$PWD"/appdmg/assets/appdmg.json
DMG_PATH="$PWD"/appdmg-$version-$(date +%s).dmg

cp $JSON_PATH".in" $JSON_PATH
perl -p -i -e "s/\@version\@/$version/g" $JSON_PATH

$APPDMG $JSON_PATH $DMG_PATH
rm $JSON_PATH

exit 0
