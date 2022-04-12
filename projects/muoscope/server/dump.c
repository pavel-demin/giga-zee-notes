#include <stdio.h>
#include <errno.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <unistd.h>
#include <sys/mman.h>
#include <fcntl.h>

int interrupted = 0;

void signal_handler(int sig)
{
  interrupted = 1;
}

int main(int argc, char *argv[])
{
  int fd_mem;
  FILE *file_out;
  volatile void *cfg, *sts;
  volatile uint8_t *rst, *cut;
  volatile uint16_t *cntr;
  volatile uint64_t *fifo;
  uint64_t data[2];

  if((fd_mem = open("/dev/mem", O_RDWR)) < 0)
  {
    perror("open");
    return EXIT_FAILURE;
  }

  sts = mmap(NULL, sysconf(_SC_PAGESIZE), PROT_READ|PROT_WRITE, MAP_SHARED, fd_mem, 0x40000000);
  cfg = mmap(NULL, sysconf(_SC_PAGESIZE), PROT_READ|PROT_WRITE, MAP_SHARED, fd_mem, 0x40001000);
  fifo = mmap(NULL, 2*sysconf(_SC_PAGESIZE), PROT_READ|PROT_WRITE, MAP_SHARED, fd_mem, 0x40002000);

  if(argc < 2)
  {
    printf("Usage: dump file\n");
    printf("file - output file.\n");
    return EXIT_FAILURE;
  }

  if((file_out = fopen(argv[1], "wb")) < 0)
  {
    perror("fopen");
    return EXIT_FAILURE;
  }

  cntr = ((uint16_t *)(sts + 0));

  rst = ((uint8_t *)(cfg + 0));

  /* reset fifo */
  *rst |= 4;
  *rst &= ~4;

  /* reset detector reader */
  *rst &= ~1;
  *rst |= 1;

  signal(SIGINT, signal_handler);

  while(!interrupted)
  {
    if(*cntr < 4)
    {
      usleep(1000);
      continue;
    }
    data[0] = *fifo;
    data[1] = *fifo;
    if(fwrite(data, 1, 16, file_out) < 0) break;
  }

  fclose(file_out);
}
