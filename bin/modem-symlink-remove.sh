#!/bin/sh

# First argument is tested against all modem symlinks and removes on match

if [ -d /dev/modems ] ; then
    for f in `ls /dev/modems/` ; do
	f="/dev/modems/$f"
	if [ `readlink $f` = "/dev/$1" ] ; then
	    /usr/local/bin/kannel-manage-smsc.rb stop `basename $f`
	    rm $f
	fi
    done
fi
