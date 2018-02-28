#! /bin/sh

mount -o rw,remount /media/mmcblk0p1
name=dump-`date +%Y%m%d-%H%M%S`
nohup ./dump $name.dat >& $name.log &
