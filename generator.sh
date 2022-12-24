#!/usr/bin/env bash
golly generator.lua
gcc ./rle-to-ppm.c -o rle-to-ppm
cat red.rle   | ./rle-to-ppm > red.ppm
cat green.rle | ./rle-to-ppm > green.ppm
cat blue.rle  | ./rle-to-ppm > blue.ppm
python3 merge.py
