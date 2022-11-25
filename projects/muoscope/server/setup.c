#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <math.h>
#include <errno.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#define I2C_SLAVE       0x0703 /* Use this slave address */
#define I2C_SLAVE_FORCE 0x0706 /* Use this slave address, even if it
                                  is already in use by a driver! */
int fd_i2c;

void set_dac(uint8_t chan, uint16_t data)
{
  uint8_t id, buffer[3];

  /* select board */
  id = 2 << (chan >> 3 & 1) | 0x38;
  if(ioctl(fd_i2c, I2C_SLAVE_FORCE, id) < 0) return;

  /* select dac */
  id = 1 << (chan >> 2 & 1) | 0xF0;
  if(write(fd_i2c, &id, 1) <= 0) return;

  id = 0x0E;
  if(ioctl(fd_i2c, I2C_SLAVE_FORCE, id) < 0) return;

  /* write data to selected dac channel */
  buffer[0] = 1 << (chan & 3);
  buffer[1] = 0x30 + (data >> 6 & 0x0F);
  buffer[2] = data << 2 & 0xFF;
  if(write(fd_i2c, buffer, 3) <= 0) return;

  /* select board */
  id = 2 << (chan >> 3 & 1) | 0x38;
  if(ioctl(fd_i2c, I2C_SLAVE_FORCE, id) < 0) return;

  /* deselect dac */
  id = 0xF0;
  if(write(fd_i2c, &id, 1) <= 0) return;
}

void configure_hv()
{
  uint8_t buffer[3];

  if(ioctl(fd_i2c, I2C_SLAVE_FORCE, 0x10) < 0) return;

  /* set DAC and ADC range to 0-2*Vref, enable ADC buffer */
  buffer[0] = 0x03;
  buffer[1] = 0x03;
  buffer[2] = 0x30;
  if(write(fd_i2c, buffer, 3) <= 0) return;

  /* enable reference and channels 0-3 */
  buffer[0] = 0x0B;
  buffer[1] = 0x02;
  buffer[2] = 0xF0;
  if(write(fd_i2c, buffer, 3) <= 0) return;

  /* configure channels 0-3 as ADC inputs */
  buffer[0] = 0x04;
  buffer[1] = 0x00;
  buffer[2] = 0x0F;
  if(write(fd_i2c, buffer, 3) <= 0) return;

  /* add channels 0-3 to the conversion sequence, enable sequence repetition */
  buffer[0] = 0x02;
  buffer[1] = 0x02;
  buffer[2] = 0x0F;
  if(write(fd_i2c, buffer, 3) <= 0) return;

  /* configure channels 2-3 as DAC outputs */
  buffer[0] = 0x05;
  buffer[1] = 0x00;
  buffer[2] = 0x0C;
  if(write(fd_i2c, buffer, 3) <= 0) return;
}

void enable_hv()
{
  uint8_t buffer;

  if(ioctl(fd_i2c, I2C_SLAVE_FORCE, 0x27) < 0) return;
  buffer = 0xFF;
  if(write(fd_i2c, &buffer, 1) <= 0) return;
}

void set_hv(uint8_t chan, uint16_t data)
{
  uint8_t buffer[3];

  if(ioctl(fd_i2c, I2C_SLAVE_FORCE, 0x10) < 0) return;

  buffer[0] = chan | 0x12;
  buffer[1] = data >> 8 & 0x0F;
  buffer[2] = data & 0xFF;
  if(write(fd_i2c, buffer, 3) <= 0) return;
}

int main(int argc, char *argv[])
{
  int i, fd_mem;
  char *end;
  long number;
  uint32_t n[23];

  volatile void *cfg;
  volatile uint8_t *rst, *wnd, *dly;

  for(i = 0; i < 23; ++i)
  {
    errno = 0;
    number = (argc == 24) ? strtol(argv[i + 1], &end, 10) : -1;
    if(errno != 0 || end == argv[i + 1] || number < 0 || number > 4095)
    {
      fprintf(stderr, "Usage: setup t0 t1 t2 t3 t4 t5 t6 t7 m0 m1 m2 m3 m4 m5 m6 m7 d0 d1 d2 d3 w v c\n");
      fprintf(stderr, " t0-t7 - threshold\n");
      fprintf(stderr, " m0-m7 - monostable\n");
      fprintf(stderr, " d0-d3 - delay\n");
      fprintf(stderr, " w - window\n");
      fprintf(stderr, " v - voltage\n");
      fprintf(stderr, " c - current\n");
      return EXIT_FAILURE;
    }
    n[i] = number;
  }

  if((fd_mem = open("/dev/mem", O_RDWR)) < 0)
  {
    perror("open");
    return EXIT_FAILURE;
  }

  cfg = mmap(NULL, sysconf(_SC_PAGESIZE), PROT_READ|PROT_WRITE, MAP_SHARED, fd_mem, 0x40001000);

  rst = ((uint8_t *)(cfg + 0));
  wnd = ((uint8_t *)(cfg + 2));
  dly = ((uint8_t *)(cfg + 4));

  if((fd_i2c = open("/dev/i2c-0", O_RDWR)) < 0)
  {
    perror("open");
    return EXIT_FAILURE;
  }

  // threshold
  set_dac(0, n[0]);
  set_dac(1, n[1]);
  set_dac(4, n[2]);
  set_dac(5, n[3]);
  set_dac(8, n[4]);
  set_dac(9, n[5]);
  set_dac(12, n[6]);
  set_dac(13, n[7]);

  // monostable
  set_dac(2, n[8]);
  set_dac(3, n[9]);
  set_dac(6, n[10]);
  set_dac(7, n[11]);
  set_dac(10, n[12]);
  set_dac(11, n[13]);
  set_dac(14, n[14]);
  set_dac(15, n[15]);

  // delay
  dly[0] = n[16];
  dly[1] = n[17];
  dly[2] = n[18];
  dly[3] = n[19];

  // window
  *wnd = n[20];

  // high voltage
  configure_hv();
  enable_hv();
  set_hv(0, n[21]);
  set_hv(1, n[22]);

  return EXIT_SUCCESS;
}
