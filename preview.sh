#!/bin/sh
# [$1 /path/to/model]
# Reads state from a named pipe
. ./asciituber.sh
. ./animations.sh

export MODEL="$1"
tmpfile=/tmp/$$
drawfile=/tmp/$$draw # tmpfile for the draw process
mkfifo "$tmpfile"
echo $$

trap 'kill $drawprocpid ; rm /tmp/$$* ; exit' int kill # clean up pipes & crocs

[ "$MODEL" ] && initangles "$MODEL" 'base'

# set this to the desired frametime (in seconds)
DELAY=0.5

export ANGLE=idle
export VIEW=current
export FRAME=1

# draw process
(
	while :
	do
		[ -f "$drawfile" ] && { # try to only set state once
			eval $(cat "$drawfile")
			rm "$drawfile"
		}
		if [ "$VIEW" = "current" ]
		then
			[ "$MODEL" ] && show "$ANGLE" || sleep "$DELAY"
		else # call the animation function
			[ "$MODEL" ] && $VIEW || sleep "$DELAY"
		fi
	done
) &
drawprocpid=$!

while :
do
	pipeval="$(cat "$tmpfile")"
	unset FRAME
	# echo "$pipeval"
	case "$pipeval" in
		'angle '*)
			ANGLE="${pipeval#* }"
			[ "$VIEW" = "current" ] && FRAME=1
			;;
		'model '*)
			MODEL="${pipeval#* }"
			initangles "$MODEL" 'base'
			;;
		'view '*)
			VIEW="${pipeval#* }"
			FRAME=1
			;;
	esac
	set > "$drawfile"
done
