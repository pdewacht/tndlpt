#include <conio.h>
#include <i86.h>
#include <string.h>
#include "emmhack.h"

int emm386_virtualize_io(int first, int last, int count,
                         void __far * table, int size, int *out_handle);
/* Interrupt list: 2F4A15BX0000 INSTALL I/O VIRTUALIZATION HANDLER */
#pragma aux emm386_virtualize_io =              \
  ".386"                                        \
  "push ax"                                     \
  "push ds"                                     \
  "mov ax, es"                                  \
  "mov ds, ax"                                  \
  "mov ax, 0x4A15"                              \
  "shl edx, 16"                                 \
  "mov dx, bx"                                  \
  "xor bx, bx"                                  \
  "stc"                                         \
  "int 0x2F"                                    \
  "pop ds"                                      \
  "pop bx"                                      \
  "mov [bx], ax"                                \
  "sbb ax, ax"                                  \
  parm [bx] [dx] [cx] [es si] [di] [ax]         \
  value [ax]                                    \
  modify [ax bx cx dx si di]

int emm386_unvirtualize_io(int handle);
#pragma aux emm386_unvirtualize_io =            \
  "mov ax, 0x4A15"                              \
  "mov bx, 1"                                   \
  "stc"                                         \
  "int 0x2F"                                    \
  "sbb ax, ax"                                  \
  parm [si]                                     \
  value [ax]                                    \
  modify [ax bx cx dx si di]

static char __far *xmemmem(const char __far * haystack,
                           size_t haystack_len,
                           const char __far * needle,
                           size_t needle_len)
{
  /* assert(needle_len > 0); */
  /* assert(haystack_len >= needle_len); */
  const char __far *p = haystack;
  const char __far *end = haystack + haystack_len - needle_len + 1;
  for (;;) {
    p = _fmemchr(p, needle[0], end - p);
    if (!p) {
      break;
    }
    if (_fmemcmp(needle, p, needle_len) == 0) {
      return (char __far *)p;
    }
    p += 1;
  }
  return 0;
}

void clc(void);
#pragma aux clc = "clc"

void cld(void);
#pragma aux cld = "cld"

#pragma aux apply_patch modify exact [ax]

static char __far apply_patch(void)
{
  // assuming CS == DS
  static const char needle[] = {
    0x83, 0x4d, 0x0c, 0x01, 0xc3, 0x0b, 0xc9, 0x0f,
    0x84, 0xb8, 0x00, 0x81, 0xfa,
  };
  char __far *match;
  int err = 1;

  cld();
  match = xmemmem(MK_FP(0xF8, 0), 0xFFFF, needle, sizeof(needle));

  if (match) {
    short __far *limit = (short __far *)(match + sizeof(needle));
    if (*limit == 0x100 || *limit == 0xC0) {
      *limit = 0xC0;
      err = 0;
    }
  }
  clc();
  return err;
}

#define PORT 0x210

int emm386_hack(void)
{
  static const int cb[2] = { PORT, (int)apply_patch };
  int err, handle;
  err = emm386_virtualize_io(PORT, PORT, 1, &cb, 0x7FFF, &handle);
  if (err) {
    return err;
  }
  err = inp(PORT);
  emm386_unvirtualize_io(handle);
  return err;
}
