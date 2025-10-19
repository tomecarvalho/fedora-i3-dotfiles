#!/usr/bin/env sh

set -eu

while true; do
    xdotool mousemove_relative -- 1 0 || true
    xdotool mousemove_relative -- -1 0 || true
    sleep 1
done
