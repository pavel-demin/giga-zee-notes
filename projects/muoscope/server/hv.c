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
  int i;
  char *end;
  long number;
  uint16_t n[2];

  for(i = 0; i < 2; ++i)
  {
    errno = 0;
    number = (argc == 3) ? strtol(argv[i + 1], &end, 10) : -1;
    if(errno != 0 || end == argv[i + 1] || number < 0 || number > 4095)
    {
      fprintf(stderr, "Usage: hv v c\n");
      fprintf(stderr, " v - voltage\n");
      fprintf(stderr, " c - current\n");
      return EXIT_FAILURE;
    }
    n[i] = number;
  }

  if((fd_i2c = open("/dev/i2c-0", O_RDWR)) < 0)
  {
    perror("open");
    return EXIT_FAILURE;
  }

  // high voltage
  configure_hv();
  enable_hv();
  set_hv(0, n[0]);
  set_hv(1, n[1]);

  return EXIT_SUCCESS;
}
