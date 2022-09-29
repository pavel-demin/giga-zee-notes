CFLAGS = -O3 -march=armv7-a -mtune=cortex-a9 -mfpu=neon -mfloat-abi=hard

all: muoscope dump setup

muoscope: muoscope.c
	gcc $(CFLAGS) -o $@ $^ -lm

dump: dump.c
	gcc $(CFLAGS) -o $@ $^ -lm

dump: setup.c
	gcc $(CFLAGS) -o $@ $^ -lm

clean:
	rm -f muoscope dump setup
