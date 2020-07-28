#!/bin/sh
set -e

(cd tndlpt && ./build.sh)
(cd tndvgm && ./build.sh)

DIR=$(mktemp -d)
cp tndlpt/tndlpt.com "$DIR/"
cp tndlpt/tndreset.exe "$DIR/"
cp tndvgm/tlpttest.exe "$DIR/"
cp tndvgm/tlpttest.vgz "$DIR/"

rm -f tndlpt.zip
zip -9j tndlpt.zip "$DIR"/*

rm -rf "$DIR"
