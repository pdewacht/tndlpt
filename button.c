#include <conio.h>
#include <dos.h>
#include <fcntl.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>



static short get_lpt_port(int i) {
  return *(short __far *)MK_FP(0x40, 6 + 2*i);
}


static void usage(void) {
  cputs("Usage: BUTTON LPT1|LPT2|LPT3\r\n");
  exit(1);
}


int main(int argc, char *argv[]) {
  int lpt_base = 0;
  int a, i, prev, stat;

  for (a = 1; a < argc; ++a) {
    const char *arg = argv[a];
    if (strnicmp(arg, "lpt", 3) == 0 && (i = arg[3] - '0') >= 1 && i <= 3) {
      lpt_base = get_lpt_port(i);
      if (!lpt_base) {
        cputs("Error: LPT");
        putch('0' + i);
        cputs(" is not present.\r\n");
        exit(1);
      }
    } else {
      usage();
    }
  }

  if (!lpt_base) {
    usage();
    return 1;
  }


  prev = -1;
  while (!kbhit()) {
    stat = inp(lpt_base + 1);
    if (stat != prev) {
      char buf[20];
      cputs("status ");
      cputs(itoa(stat, buf, 16));
      cputs("h = ");
      cputs(1 + itoa(stat|0x100, buf, 2));
      cputs("\r\n");
      prev = stat;
    }
  }

  while (kbhit()) {
    getch();
  }
  return 0;
}
