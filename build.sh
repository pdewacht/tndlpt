#!/bin/sh
set -e

VERSION_MAJOR=0
VERSION_MINOR=9

CC='wcc -bt=dos -zq -oxhs'
CC32='wcc386 -mf -zl -zls -zq -oxhs'
AS='wasm -zq'
DEFS="-dVERSION_MAJOR=$VERSION_MAJOR -dVERSION_MINOR=$VERSION_MINOR"
#DEFS="$DEFS -dDEBUG"

set -x
$CC $DEFS tndlpt.c
$AS $DEFS resident.s
$AS $DEFS res_end.s
wlink @tndlpt.wl

$CC $DEFS button.c
wlink name button file button system dos option quiet
