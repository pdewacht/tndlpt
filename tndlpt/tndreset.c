#include <string.h>
#include <i86.h>
#include "tndlpt.h"

int tndlpt_port;

int main(int argc, char *argv[])
{
  int lpt = 1;
  short port;
  if (argc > 1) {
    if (strnicmp(argv[1], "lpt2", 4)) {
      lpt = 2;
    } else if (strnicmp(argv[1], "lpt3", 4)) {
      lpt = 3;
    }
  }
  tndlpt_port = *(short __far *)MK_FP(0x40, 6 + 2 * lpt);
  tndlpt_init(false);
  return 0;
}
