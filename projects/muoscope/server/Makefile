CFLAGS = -O3 -march=armv7-a -mcpu=cortex-a9 -mtune=cortex-a9 -mfpu=neon -mfloat-abi=hard

all: muoscope dump

muoscope: muoscope.c
	gcc $(CFLAGS) -o $@ $^ -lm

dump: dump.c
	gcc $(CFLAGS) -o $@ $^ -lm

clean:
	rm -f muoscope dump
