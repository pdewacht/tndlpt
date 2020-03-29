#!/bin/sh
set -e

VERSION_MAJOR=0
VERSION_MINOR=11

CC='wcc -bt=dos -zq -oxhs'
CC32='wcc386 -mf -zl -zls -zq -oxhs'
AS='wasm -zq'
DEFS="-dVERSION_MAJOR=$VERSION_MAJOR -dVERSION_MINOR=$VERSION_MINOR"
#DEFS="$DEFS -dDEBUG"

set -x
ragel -T1 cmdline.rl
$CC $DEFS tndlpt.c
$CC $DEFS emmhack.c
$CC $DEFS cmdline.c
$CC $DEFS tndinit.c
$CC $DEFS tndout.c
$CC $DEFS res_data.c
$AS $DEFS resident.s
$AS $DEFS res_end.s
wlink @tndlpt.wl

$CC $DEFS tndreset.c
wlink name tndreset file tndreset,tndinit,tndout system dos option quiet
