#!/bin/bash

if [ $# -ne 2 ]
then
	echo "There should be two arguments"
fi

oldmoduleversion=$1
newmoduleversion=$2

grep -ril "${oldmoduleversion}\." * &>/dev/null
if [ $? -ne 0 ]
then
	echo "No matches found"
	exit
fi

perl -p -i -e "s/${oldmoduleversion}\./${newmoduleversion}\./g" `grep -ril "${oldmoduleversion}\." *`
