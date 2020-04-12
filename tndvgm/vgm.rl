/* -*- Mode: C -*- */
#include <stdbool.h>
#include <stdio.h>
#include <string.h>
#include "zlib/zlib.h"
#include "../tndlpt/tndlpt.h"
#include "timer.h"
#include "vgm.h"

extern void warnx(const char *fmt, ...);

#define TIMER_HZ 300
#define VGM_TICKS_PER_TIMER_TICK (44100 / TIMER_HZ)

struct vgm_state {
  int cs;
  unsigned char __near *p;
  unsigned char __near *pe;

  gzFile f;
  unsigned char buf[8192];
  long remaining;

  long ticks;
  long delay;
  unsigned long arg;
  char warning_flag[256];
};

static struct vgm_state vgm;

%%{
machine vgm;

alphtype unsigned char;
variable cs vgm.cs;
variable p vgm.p;
variable pe vgm.pe;

action end            { fhold; return false; }
action set_delay      { vgm.delay = vgm.arg; }
action set_delay_60hz { vgm.delay = 735; }
action set_delay_50hz { vgm.delay = 882; }
action set_delay_tiny { vgm.delay = (fc & 0xF) + 1; }
action output_psg     { tndlpt_output(fc); }
action unimplemented  { warn_unimplemented(); }

any2 = any.any;
any3 = any.any.any;
any4 = any.any.any.any;

arg1 = any @{vgm.arg = fc;};
arg2 = arg1 . any @{vgm.arg |= fc << 8;};
arg3 = arg2 . any @{vgm.arg |= fc << 16;};
arg4 = arg3 . any @{vgm.arg |= fc << 24;};

unimplemented =
  ( 0x4F.any    # Game Gear PSG stereo
  | 0x51.any2   # YM2413
  | 0x52.any2   # YM2612 port 0
  | 0x53.any2   # YM2612 port 1
  | 0x54.any2   # YM2151
  | 0x55.any2   # YM2203
  | 0x56.any2   # YM2608 port 0
  | 0x57.any2   # YM2608 port 1
  | 0x58.any2   # YM2610 port 0
  | 0x59.any2   # YM2610 port 1
  | 0x5A.any2   # YM3812
  | 0x5B.any2   # YM3526
  | 0x5C.any2   # Y8950
  | 0x5D.any2   # YMZ280B
  | 0x5E.any2   # YMF262 port 0
  | 0x5F.any2   # YMF262 port 1
  | 0x64.any3   # override length of 0x62/0x63
  | 0x67        # Datablock
  | 0x68        # PCM RAM write
  | 0x80..0x8F  # YM2612 port 0 address 2A write from the data bank
  | 0x90..0x95  # DAC Stream Control Write
  | 0xA0.any2   # AY8910
  | 0xB0.any2   # RF5C68
  | 0xB1.any2   # RF5C164
  | 0xB2.any2   # PWM
  | 0xB3.any2   # GameBoy DMG
  | 0xB4.any2   # NES APU
  | 0xB5.any2   # MultiPCM
  | 0xB6.any2   # uPD7759
  | 0xB7.any2   # OKIM6258
  | 0xB8.any2   # OKIM6295
  | 0xB9.any2   # HuC6280
  | 0xBA.any2   # K053260
  | 0xBB.any2   # Pokey
  | 0xBC.any2   # WonderSwan
  | 0xBD.any2   # SAA1099
  | 0xBE.any2   # ES5506
  | 0xBF.any2   # GA20
  | 0xC0.any3   # Sega PCM
  | 0xC1.any3   # RF5C68
  | 0xC2.any3   # RF5C164
  | 0xC3.any3   # MultiPCM
  | 0xC4.any3   # QSound
  | 0xC5.any3   # SCSP
  | 0xC6.any3   # WonderSwan
  | 0xC7.any3   # VSU
  | 0xC8.any3   # X1-010
  | 0xD0.any3   # YMF278B, port pp
  | 0xD1.any3   # YMF271, port pp
  | 0xD2.any3   # SCC1, port pp
  | 0xD3.any3   # K054539
  | 0xD4.any3   # C140
  | 0xD5.any3   # ES5503
  | 0xD6.any3   # ES5506
  | 0xE0.any4   # YM2612: Seek in PCM data bank
  | 0xE1.any4   # C352
  | (0x30..0x3F).any   # reserved for future use
  | (0x40..0x4E).any2  # reserved for future use
  | (0xA1..0xAF).any2  # reserved for future use
  | (0xC9..0xCF).any3  # reserved for future use
  | (0xD7..0xDF).any3  # reserved for future use
  | (0xE2..0xFF).any4  # reserved for future use
  );

command =
  ( 0x50.any      @output_psg
  | 0x61.arg2     @set_delay
  | 0x62          @set_delay_60hz
  | 0x63          @set_delay_50hz
  | 0x66          @end
  | 0x70..0x7F    @set_delay_tiny
  | unimplemented >unimplemented
  );

main := (command @{fbreak;})**;

write data;
}%%

static void warn_unimplemented(void)
{
  unsigned char cmd = *vgm.p;
  if (!vgm.warning_flag[cmd]) {
    vgm.warning_flag[cmd] = 1;
    warnx("Warning: skipping unimplemented command %02Xh", cmd);
  }
}

static bool refill(void)
{
  int used, unused, to_read, result;
  unsigned char __near *dest;

  used = vgm.pe - vgm.p;
  unused = sizeof(vgm.buf) - used;
  dest = vgm.buf + used;
  memmove(vgm.buf, vgm.p, used);

  if (vgm.remaining > unused) {
    to_read = unused;
  } else {
    to_read = vgm.remaining;
  }

  result = gzread(vgm.f, dest, to_read);
  if (result < 0) {
    warnx("Read error");
    return false;
  }
  if (result == 0) {
    warnx("Unexpected end of file");
    return false;
  }

  vgm.p = vgm.buf;
  vgm.pe = dest + result;
  vgm.remaining -= result;
  return true;
}

bool music_setup(gzFile f)
{
  unsigned long header[64];
  unsigned long version, psg_hz;
  long fpos_start, fpos_end;

  if (gzread(f, header, 256) != 256) {
    return false;
  }

  /* Check valid header */
  if (header[0] != 0x206D6756UL) {
    return false;
  }
  version = header[2];

  /* Find begin and end offsets */
  if (version < 0x0150UL) {
    fpos_start = 0x40;
  } else {
    fpos_start = header[13] + 0x34;
  }
  fpos_end = header[1] + 4;
  if (fpos_start < 0 || fpos_end <= fpos_start) {
    return false;
  }

  /* Check Tandy file */
  psg_hz = header[3];
  if (!psg_hz) {
    return false;
  }
  if (psg_hz != 3579545) {
    warnx("Warning: Unexpected PSG frequency %luHz", psg_hz);
  }

  /* OK */
  memset(&vgm, 0, sizeof(vgm));
  %%write init;
  vgm.f = f;
  vgm.remaining = fpos_end - fpos_start;

  gzseek(f, fpos_start - 256, SEEK_CUR);
  if (!refill()) {
    return false;
  }

  return true;
}

void music_start(void)
{
  timer_setup(TIMER_HZ);
}

void music_shutdown(void)
{
  timer_shutdown();

  tndlpt_output(0x9F);
  tndlpt_output(0xBF);
  tndlpt_output(0xDF);
  tndlpt_output(0xFF);
}

bool music_loop(void)
{
  vgm.ticks += timer_get_elapsed() * VGM_TICKS_PER_TIMER_TICK;
  if (vgm.delay > 16) {
    if (vgm.ticks < vgm.delay) {
      /* Delay a bit */
      if (vgm.remaining > 0 && (vgm.pe - vgm.p) < sizeof(vgm.buf) / 4) {
        return refill();
      }
      hlt();
      return true;
    }
  }
  vgm.ticks -= vgm.delay;
  vgm.delay = 0;

  %%write exec;

  if (vgm.cs == vgm_error) {
    warnx("VGM format error, cmd=%02Xh", *vgm.p);
    return false;
  }
  if (vgm.p == vgm.pe) {
    if (vgm.remaining == 0) {
      return false;
    }
    return refill();
  }
  return true;
}
