#include <conio.h>
#include "tndlpt.h"

void tndlpt_debug(void)
{
  char stat[80];
  int i;

  outp(tndlpt_port, 0xFF);
  outp(tndlpt_port + 2, 0x0C);
  for (i = 0; i < sizeof(stat); i++) {
    stat[i] = inp(tndlpt_port + 1);
  }
  outp(tndlpt_port + 2, 0x09);

  cputs("Ready test\r\n");
  for (i = 0; i < sizeof(stat); i++) {
    cprintf((stat[i] & 0x40)
            ? "% 3d NOT RDY     "
            : "% 3d READY       ",
            i + 1);
  }
  cputs("\r\n");
}
