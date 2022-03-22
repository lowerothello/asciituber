#!/bin/sh
# [$1 /path/to/model]
# Reads state from a named pipe
. ./asciituber.sh

export MODEL="$1"
tmpfile=/tmp/$$
drawfile=/tmp/$$draw # tmpfile for the draw process
mkfifo "$tmpfile" "$drawfile"
echo $$

trap 'rm /tmp/$$* ; kill $drawprocpid ; exit' int kill # clean up the pipes

[ "$MODEL" ] && initangles "$MODEL" 'base'

# set this to the desired frametime (in seconds)
DELAY=0.2

export ANGLE=idle
export VIEW=current

# draw process
(
	while :
	do
		eval $(cat "$drawfile")
		[ "$VIEW" = "current" ] && {
			[ "$MODEL" ] && angle "$ANGLE"
		} || { # call the animation function
			[ "$MODEL" ] && $VIEW
		}
	done
) &
drawprocpid=$!

while :
do
	pipeval="$(cat "$tmpfile")"
	# echo "$pipeval"
	case "$pipeval" in
		'angle '*)
			ANGLE="${pipeval#* }"
			;;
		'model '*)
			MODEL="${pipeval#* }"
			initangles "$MODEL" 'base'
			;;
		'view '*)
			VIEW="${pipeval#* }"
			;;
	esac
	set > "$drawfile"
done
