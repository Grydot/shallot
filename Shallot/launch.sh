#!/bin/sh
scriptdir=/mnt/SDCARD/App/Shallot

touch /tmp/stay_awake

cd $scriptdir
st -q -e sh $scriptdir/shallot.sh
