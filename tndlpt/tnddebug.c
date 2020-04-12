#include <conio.h>
#include "tndlpt.h"

void tndlpt_debug(void)
{
  char stat[80];
  int i, r, c;

  outp(tndlpt_port, 0xFF);
  outp(tndlpt_port + 2, 0x0C);
  for (i = 0; i < sizeof(stat); i++) {
    stat[i] = inp(tndlpt_port + 1);
  }
  outp(tndlpt_port + 2, 0x09);

  cputs("Ready test\r\n");
  for (r = 0; r < sizeof(stat) / 5; r++) {
    for (c = 0; c < 5; c++) {
      i = c * sizeof(stat) / 5 + r;
      cprintf((stat[i] & 0x40)
              ? "% 3d READY       "
              : "% 3d NOT RDY     ",
              i + 1);
    }
  }
  cputs("\r\n");
}
