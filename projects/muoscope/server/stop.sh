#! /bin/sh

killall -q -s SIGINT dump
mount -o ro,remount /media/mmcblk0p1
