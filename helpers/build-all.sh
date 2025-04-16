source /opt/Xilinx/Vitis/2024.2/settings64.sh

JOBS=`nproc 2> /dev/null || echo 1`

make -j $JOBS cores

make NAME=led_blinker all

PRJS="muoscope"

printf "%s\n" $PRJS | xargs -n 1 -P $JOBS -I {} make NAME={} bit

sudo sh scripts/alpine.sh
