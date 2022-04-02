#!/bin/sh

run() {
	echo "$@"
	$@
}

run ${CC:-gcc} $CFLAGS drawblock.c -o drawblock
