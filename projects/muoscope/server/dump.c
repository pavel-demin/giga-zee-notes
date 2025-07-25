#include <stdio.h>
#include <errno.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <unistd.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <time.h>

int interrupted = 0;

void signal_handler(int sig)
{
  interrupted = 1;
}

int main(int argc, char *argv[])
{
  int fd_mem;
  FILE *file_out;
  struct timespec t;
  volatile void *cfg, *sts;
  volatile uint8_t *rst, *cut;
  volatile uint16_t *cntr;
  volatile uint64_t *fifo;
  uint64_t data[2];

  if(argc < 2)
  {
    fprintf(stderr, "Usage: dump file\n");
    fprintf(stderr, " file - output file\n");
    return EXIT_FAILURE;
  }

  if((fd_mem = open("/dev/mem", O_RDWR)) < 0)
  {
    perror("open");
    return EXIT_FAILURE;
  }

  if((file_out = fopen(argv[1], "wb")) < 0)
  {
    perror("fopen");
    return EXIT_FAILURE;
  }

  cfg = mmap(NULL, sysconf(_SC_PAGESIZE), PROT_READ|PROT_WRITE, MAP_SHARED, fd_mem, 0x40000000);
  sts = mmap(NULL, sysconf(_SC_PAGESIZE), PROT_READ|PROT_WRITE, MAP_SHARED, fd_mem, 0x41000000);
  fifo = mmap(NULL, 32*sysconf(_SC_PAGESIZE), PROT_READ|PROT_WRITE, MAP_SHARED, fd_mem, 0x42000000);

  cntr = ((uint16_t *)(sts + 0));

  rst = ((uint8_t *)(cfg + 0));

  clock_gettime(CLOCK_REALTIME, &t);

  if(fwrite(&t, 1, sizeof(t), file_out) < 0)
  {
    perror("fwrite");
    return EXIT_FAILURE;
  }

  /* reset fifo */
  *rst &= ~2;
  *rst |= 2;

  /* reset detector reader */
  *rst &= ~1;
  *rst |= 1;

  signal(SIGINT, signal_handler);

  while(!interrupted)
  {
    if(*cntr > 32760)
    {
      fprintf(stderr, "FIFO buffer is full\n");
    }

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
