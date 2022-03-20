#!/bin/sh -e
# [$1 /path/to/model]
. ./asciituber.sh

initangles "$1" 'base'
baseAngle="idle" draw "$1"
