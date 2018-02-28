#! /bin/sh

apps_dir=/media/mmcblk0p1/apps

source $apps_dir/stop.sh

cat $apps_dir/muoscope/muoscope.bit > /dev/xdevcfg

$apps_dir/muoscope/muoscope &
