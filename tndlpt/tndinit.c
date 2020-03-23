#include <conio.h>
#include <i86.h>
#include "tndlpt.h"


int tndlpt_init(int lpt_port) {
  int dcr = lpt_port + 2;
  int ecr = lpt_port + 0x402;
  tndlpt_port = lpt_port;

  /* Disable ECP */
  outp(dcr, 0x00);
  if ((inp(ecr) & 3) == 1) {
    outp(ecr, 0x00);
  }

  /* Initialize the sound chip */
  if (!tndlpt_output(0x9F)) {
    return 0;
  }
  tndlpt_output(0xBF);
  tndlpt_output(0xDF);
  tndlpt_output(0xFF);

  /* Disable the mute circuit */
  outp(dcr, 0x07);
  delay(200);
  outp(dcr, 0x09);

  return 1;
}
