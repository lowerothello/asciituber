#!/bin/sh -e
# [$1 /path/to/model]
. ./drawlib.sh

initangles "$1" 'base'
baseAngle="idle" draw "$1"
