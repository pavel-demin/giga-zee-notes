#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <math.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#define I2C_SLAVE       0x0703 /* Use this slave address */
#define I2C_SLAVE_FORCE 0x0706 /* Use this slave address, even if it
                                  is already in use by a driver! */

struct COMMAND
{
  uint16_t data;
  uint8_t chan;
  uint8_t code;
};

int fd_i2c;

void get_adc(int sock_client)
{
  int i, j;
  uint8_t buffer[8];
  float ref[4] = {2.5, 2.5, 5.0, 5.0};
  float result[21];

  memset(result, 0, 84);

  for(i = 0; i < 4; ++i)
  {
    if(ioctl(fd_i2c, I2C_SLAVE_FORCE, i + 0x2A) < 0) continue;

    for(j = 0; j < 4; ++j)
    {
      buffer[0] = 0x01;
      buffer[1] = (j + 1) << 5;
      if(write(fd_i2c, buffer, 2) <= 0) continue;
      buffer[0] = 0x04;
      if(write(fd_i2c, buffer, 1) <= 0) continue;
      usleep(1000);
      if(read(fd_i2c, buffer, 2) <= 0) continue;
      result[i * 4 + j] = ((float)buffer[0] * 4.0 + (float)(buffer[1] >> 6)) * ref[j] / 1024.0;
    }
  }

  ioctl(fd_i2c, I2C_SLAVE_FORCE, 0x10);

  buffer[0] = 0x40;
  write(fd_i2c, buffer, 1);

  read(fd_i2c, buffer, 8);

  for(i = 0; i < 4; ++i)
  {
    result[i + 16] = ((float)(buffer[i * 2 + 0] & 0x0F) * 256.0 + (float)buffer[i * 2 + 1]) * 5.0 / 4096.0;
  }

  ioctl(fd_i2c, I2C_SLAVE_FORCE, 0x27);
  read(fd_i2c, buffer, 1);
  result[20] = buffer[0] >> 4 & 1;

  send(sock_client, result, 84, MSG_NOSIGNAL);
}

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
  uint8_t id, buffer[3];

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
  int fd_mem, sock_server, sock_client;
  struct sockaddr_in addr;
  struct COMMAND command;
  uint16_t data;
  uint8_t code, chan, buffer;
  int yes = 1;

  volatile void *cfg;
  volatile uint8_t *wnd, *dly;

  if((fd_mem = open("/dev/mem", O_RDWR)) < 0)
  {
    perror("open");
    return EXIT_FAILURE;
  }

  cfg = mmap(NULL, sysconf(_SC_PAGESIZE), PROT_READ|PROT_WRITE, MAP_SHARED, fd_mem, 0x40000000);

  wnd = ((uint8_t *)(cfg + 2));
  dly = ((uint8_t *)(cfg + 4));

  *wnd = 9;
  dly[0] = 0;
  dly[1] = 0;
  dly[2] = 0;
  dly[3] = 0;

  if((fd_i2c = open("/dev/i2c-0", O_RDWR)) < 0)
  {
    perror("open");
    return EXIT_FAILURE;
  }

  configure_hv();

  if((sock_server = socket(AF_INET, SOCK_STREAM, 0)) < 0)
  {
    perror("socket");
    return EXIT_FAILURE;
  }

  setsockopt(sock_server, SOL_SOCKET, SO_REUSEADDR, (void *)&yes , sizeof(yes));

  /* setup listening address */
  memset(&addr, 0, sizeof(addr));
  addr.sin_family = AF_INET;
  addr.sin_addr.s_addr = htonl(INADDR_ANY);
  addr.sin_port = htons(1001);

  if(bind(sock_server, (struct sockaddr *)&addr, sizeof(addr)) < 0)
  {
    perror("bind");
    return EXIT_FAILURE;
  }

  listen(sock_server, 1024);

  while(1)
  {
    if((sock_client = accept(sock_server, NULL, NULL)) < 0)
    {
      perror("accept");
      return EXIT_FAILURE;
    }

    while(1)
    {
      if(recv(sock_client, (char *)&command, 4, MSG_WAITALL) <= 0) break;
      code = command.code;
      chan = command.chan;
      data = command.data;
      switch(code)
      {
        case 0:
          get_adc(sock_client);
          break;
        case 1:
          set_dac(chan, data);
          break;
        case 2:
          set_hv(chan, data);
          break;
        case 3:
          if(ioctl(fd_i2c, I2C_SLAVE_FORCE, 0x27) < 0) break;
          buffer = data > 0 ? 0xFF : 0xEF;
          write(fd_i2c, &buffer, 1);
          break;
        case 4:
          *wnd = data;
          break;
        case 5:
          if(chan > 3) break;
          dly[chan] = data;
          break;
      }
    }

    close(sock_client);
  }

  close(sock_server);

  return EXIT_SUCCESS;
}
