alpine_url=http://dl-cdn.alpinelinux.org/alpine/v3.22

tools_tar=apk-tools-static-2.14.9-r2.apk
tools_url=$alpine_url/main/armv7/$tools_tar

firmware_tar=linux-firmware-other-20250509-r0.apk
firmware_url=$alpine_url/main/armv7/$firmware_tar

linux_dir=tmp/linux-6.12
linux_ver=6.12.29-xilinx

modules_dir=alpine-modloop/lib/modules/$linux_ver

passwd=changeme

test -f $tools_tar || curl -L $tools_url -o $tools_tar

test -f $firmware_tar || curl -L $firmware_url -o $firmware_tar

for tar in linux-firmware-ath9k_htc-20250509-r0.apk linux-firmware-brcm-20250509-r0.apk linux-firmware-cypress-20250509-r0.apk linux-firmware-rtlwifi-20250509-r0.apk
do
  url=$alpine_url/main/armv7/$tar
  test -f $tar || curl -L $url -o $tar
done

mkdir alpine-apk
tar -zxf $tools_tar --directory=alpine-apk --warning=no-unknown-keyword

mkdir -p $modules_dir/kernel

find $linux_dir -name \*.ko -printf '%P\0' | tar --directory=$linux_dir --owner=0 --group=0 --null --files-from=- -zcf - | tar -zxf - --directory=$modules_dir/kernel

cp $linux_dir/modules.order $linux_dir/modules.builtin $modules_dir/

depmod -a -b alpine-modloop $linux_ver

tar -zxf $firmware_tar --directory=alpine-modloop/lib/modules --warning=no-unknown-keyword --strip-components=1 --wildcards lib/firmware/ar* lib/firmware/rt*

for tar in linux-firmware-ath9k_htc-20250509-r0.apk linux-firmware-brcm-20250509-r0.apk linux-firmware-cypress-20250509-r0.apk linux-firmware-rtlwifi-20250509-r0.apk
do
  tar -zxf $tar --directory=alpine-modloop/lib/modules --warning=no-unknown-keyword --strip-components=1
done

mksquashfs alpine-modloop/lib modloop -b 1048576 -comp xz -Xdict-size 100%

rm -rf alpine-modloop

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

projects="led_blinker muoscope"

for p in $projects
do
  mkdir -p $root_dir/media/mmcblk0p1/apps/$p
  cp -r projects/$p/server/* $root_dir/media/mmcblk0p1/apps/$p/
  cp -r projects/$p/app/* $root_dir/media/mmcblk0p1/apps/$p/
  cp tmp/$p.bit $root_dir/media/mmcblk0p1/apps/$p/
done

cp -r alpine-apk/sbin $root_dir/

chroot $root_dir /sbin/apk.static --repository $alpine_url/main --update-cache --allow-untrusted --initdb add alpine-base

echo $alpine_url/main > $root_dir/etc/apk/repositories
echo $alpine_url/community >> $root_dir/etc/apk/repositories

chroot $root_dir /bin/sh <<- EOF_CHROOT

apk update
apk add openssh ucspi-tcp6 iw wpa_supplicant dhcpcd dnsmasq hostapd iptables avahi dbus dcron chrony musl-dev curl wget less nano bc dos2unix screen

rc-update add bootmisc boot
rc-update add hostname boot
rc-update add swclock boot
rc-update add sysctl boot
rc-update add syslog boot
rc-update add seedrng boot

rc-update add killprocs shutdown
rc-update add mount-ro shutdown
rc-update add savecache shutdown

rc-update add devfs sysinit
rc-update add dmesg sysinit
rc-update add mdev sysinit
rc-update add hwdrivers sysinit
rc-update add modloop sysinit

rc-update add avahi-daemon default
rc-update add chronyd default
rc-update add dhcpcd default
rc-update add local default
rc-update add dcron default
rc-update add sshd default

rc-update add dnsmasq default

mkdir -p etc/runlevels/wifi
rc-update -s add default wifi

rc-update add iptables wifi
rc-update add hostapd wifi

sed -i 's/^SAVE_ON_STOP=.*/SAVE_ON_STOP="no"/;s/^IPFORWARD=.*/IPFORWARD="yes"/' etc/conf.d/iptables

sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' etc/ssh/sshd_config

echo root:$passwd | chpasswd

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

apk add make gcc

for p in server $projects
do
  make -C /media/mmcblk0p1/apps/\$p clean
  make -C /media/mmcblk0p1/apps/\$p
done

EOF_CHROOT

cp -r $root_dir/media/mmcblk0p1/apps .
cp -r $root_dir/media/mmcblk0p1/cache .
cp $root_dir/media/mmcblk0p1/giga-zee.apkovl.tar.gz .

cp -r alpine/wifi .

hostname -F /etc/hostname

rm -rf $root_dir alpine-apk

zip -r giga-zee-alpine-3.22-armv7-`date +%Y%m%d`.zip apps boot.bin cache giga-zee.apkovl.tar.gz modloop wifi

rm -rf apps cache giga-zee.apkovl.tar.gz modloop wifi
