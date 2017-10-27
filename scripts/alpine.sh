alpine_url=http://dl-cdn.alpinelinux.org/alpine/v3.6

uboot_tar=alpine-uboot-3.6.2-armhf.tar.gz
uboot_url=$alpine_url/releases/armhf/$uboot_tar

tools_tar=apk-tools-static-2.7.3-r0.apk
tools_url=$alpine_url/main/armhf/$tools_tar

firmware_tar=linux-firmware-20170330-r1.apk
firmware_url=$alpine_url/main/armhf/$firmware_tar

linux_dir=tmp/linux-xlnx-xilinx-v2016.4
linux_ver=4.6.0-xilinx

modules_dir=alpine-modloop/lib/modules/$linux_ver

apks_tar=apks.tgz
apks_url=https://www.dropbox.com/sh/5fy49wae6xwxa8a/AADaQEPEtSBiYXU814k4jDR4a/apks.tgz?dl=1

passwd=changeme

test -f $uboot_tar || curl -L $uboot_url -o $uboot_tar
test -f $tools_tar || curl -L $tools_url -o $tools_tar
test -f $firmware_tar || curl -L $firmware_url -o $firmware_tar
test -f $apks_tar || curl -L $apks_url -o $apks_tar

tar -zxf $apks_tar
touch apks/.boot_repository

mkdir alpine-uboot
tar -zxf $uboot_tar --directory=alpine-uboot

mkdir alpine-apk
tar -zxf $tools_tar --directory=alpine-apk --warning=no-unknown-keyword

mkdir alpine-initramfs
cd alpine-initramfs

gzip -dc ../alpine-uboot/boot/initramfs-hardened | cpio -id
rm -rf etc/modprobe.d
rm -rf lib/firmware
rm -rf lib/modules
find . | sort | cpio --quiet -o -H newc | gzip -9 > ../initrd.gz

cd ..

mkimage -A arm -T ramdisk -C gzip -d initrd.gz uInitrd

mkdir -p $modules_dir/kernel

find $linux_dir -name \*.ko -printf '%P\0' | tar --directory=$linux_dir --owner=0 --group=0 --null --files-from=- -zcf - | tar -zxf - --directory=$modules_dir/kernel

cp $linux_dir/modules.order $linux_dir/modules.builtin $modules_dir/

depmod -a -b alpine-modloop $linux_ver

tar -zxf $firmware_tar --directory=alpine-modloop/lib/modules --warning=no-unknown-keyword --strip-components=1 --wildcards lib/firmware/ar* lib/firmware/ath* lib/firmware/brcm* lib/firmware/ht* lib/firmware/rt* lib/firmware/RT*

mksquashfs alpine-modloop/lib modloop -b 1048576 -comp xz -Xdict-size 100%

rm -rf alpine-uboot alpine-initramfs initrd.gz alpine-modloop

root_dir=alpine-root

mkdir -p $root_dir/usr/bin
cp /usr/bin/qemu-arm-static $root_dir/usr/bin/

mkdir -p $root_dir/etc
cp /etc/resolv.conf $root_dir/etc/

mkdir -p $root_dir/etc/apk
mkdir -p $root_dir/media/mmcblk0p1/cache
ln -s /media/mmcblk0p1/cache $root_dir/etc/apk/cache

cp -r alpine/etc $root_dir/
cp -r alpine/apps $root_dir/media/mmcblk0p1/

cp -r apks $root_dir/media/mmcblk0p1/
 
for project in led_blinker
do
  mkdir -p $root_dir/media/mmcblk0p1/apps/$project
  cp -r projects/$project/server/* $root_dir/media/mmcblk0p1/apps/$project/
  cp -r projects/$project/app/* $root_dir/media/mmcblk0p1/apps/$project/
  cp tmp/$project.bit $root_dir/media/mmcblk0p1/apps/$project/
done

cp -r alpine-apk/sbin $root_dir/

chroot $root_dir /sbin/apk.static --repository $alpine_url/main --update-cache --allow-untrusted --initdb add alpine-base

echo /media/mmcblk0p1/apks > $root_dir/etc/apk/repositories
echo $alpine_url/main >> $root_dir/etc/apk/repositories
echo $alpine_url/community >> $root_dir/etc/apk/repositories

chroot $root_dir /bin/sh <<- EOF_CHROOT

apk update
apk add openssh iw wpa_supplicant dhcpcd dnsmasq hostapd-rtl871xdrv iptables avahi dcron chrony gpsd-timepps musl-dev fftw-dev libconfig-dev alsa-lib-dev alsa-utils curl wget less nano bc

ln -s /etc/init.d/bootmisc etc/runlevels/boot/bootmisc
ln -s /etc/init.d/hostname etc/runlevels/boot/hostname
ln -s /etc/init.d/hwdrivers etc/runlevels/boot/hwdrivers
ln -s /etc/init.d/modloop etc/runlevels/boot/modloop
ln -s /etc/init.d/swclock etc/runlevels/boot/swclock
ln -s /etc/init.d/sysctl etc/runlevels/boot/sysctl
ln -s /etc/init.d/syslog etc/runlevels/boot/syslog
ln -s /etc/init.d/urandom etc/runlevels/boot/urandom

ln -s /etc/init.d/killprocs etc/runlevels/shutdown/killprocs
ln -s /etc/init.d/mount-ro etc/runlevels/shutdown/mount-ro
ln -s /etc/init.d/savecache etc/runlevels/shutdown/savecache

ln -s /etc/init.d/devfs etc/runlevels/sysinit/devfs
ln -s /etc/init.d/dmesg etc/runlevels/sysinit/dmesg
ln -s /etc/init.d/mdev etc/runlevels/sysinit/mdev

rc-update add avahi-daemon default
rc-update add chronyd default
rc-update add dhcpcd default
rc-update add inetd default
rc-update add local default
rc-update add dcron default
rc-update add sshd default

mkdir -p etc/runlevels/wifi
rc-update -s add default wifi

rc-update add iptables wifi
rc-update add dnsmasq wifi
rc-update add hostapd wifi

sed -i 's/^SAVE_ON_STOP=.*/SAVE_ON_STOP="no"/;s/^IPFORWARD=.*/IPFORWARD="yes"/' etc/conf.d/iptables

sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' etc/ssh/sshd_config

echo root:$passwd | chpasswd

setup-hostname giga-zee
hostname giga-zee

sed -i 's/^# LBU_MEDIA=.*/LBU_MEDIA=mmcblk0p1/' etc/lbu/lbu.conf

cat <<- EOF_CAT > root/.profile
alias rw='mount -o rw,remount /media/mmcblk0p1'
alias ro='mount -o ro,remount /media/mmcblk0p1'
EOF_CAT

ln -s /media/mmcblk0p1/apps root/apps
ln -s /media/mmcblk0p1/wifi root/wifi

lbu add root
lbu delete etc/resolv.conf
lbu delete root/.ash_history

lbu commit -d

apk add subversion make gcc

for project in server
do
  make -C /media/mmcblk0p1/apps/\$project clean
  make -C /media/mmcblk0p1/apps/\$project
done

EOF_CHROOT

cp -r $root_dir/media/mmcblk0p1/apps .
cp -r $root_dir/media/mmcblk0p1/cache .
cp $root_dir/media/mmcblk0p1/giga-zee.apkovl.tar.gz .

cp -r alpine/wifi .

hostname -F /etc/hostname

rm -rf $root_dir alpine-apk 

zip -r giga-zee-alpine-3.6-armhf-`date +%Y%m%d`.zip apks apps boot.bin cache devicetree.dtb giga-zee.apkovl.tar.gz modloop uEnv.txt uImage uInitrd wifi

rm -rf apks apps cache giga-zee.apkovl.tar.gz modloop uInitrd wifi
