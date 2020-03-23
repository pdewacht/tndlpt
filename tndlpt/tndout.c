#include <conio.h>
#include "tndlpt.h"

int tndlpt_output(char cmd_byte)
{
  int port = tndlpt_port;
  int wait = 24;
  outp(port, cmd_byte);
  port += 2;
  outp(port, 0x0C);
  port -= 1;
  while ((inp(port) & 0x40) != 0) {
    if (--wait == 0) {
      goto timeout;
    }
  }
  while ((inp(port) & 0x40) == 0) {
    if (--wait == 0) {
      goto timeout;
    }
  }
 timeout:
  port += 1;
  outp(port, 0x09);
  return wait;
}
