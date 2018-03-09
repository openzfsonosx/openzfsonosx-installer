#!/bin/bash -x

if [ $# -ne 2 ]
then
	echo "There should be two arguments"
fi

oldmoduleversion=$1
newmoduleversion=$2

grep -ril "2012-${oldmoduleversion}" * &>/dev/null
if [ $? -ne 0 ]
then
	echo "No matches found"
	exit
fi

perl -p -i -e "s/2012-${oldmoduleversion}/2012-${newmoduleversion}/g" `grep -ril "2012-${oldmoduleversion}" *`
