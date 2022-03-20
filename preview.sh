#!/bin/sh -e
# [$1 /path/to/model]
# Reads state from a named pipe
. ./drawlib.sh

MODEL="$1"
tmpfile=/tmp/$$
drawfile=/tmp/$$draw # tmpfile for the draw process
mkfifo "$tmpfile" "$drawfile"
echo $$

trap 'rm /tmp/$$* ; kill $drawprocpid ; exit' int kill # clean up the pipes

[ "$MODEL" ] && initangles "$MODEL" 'base'

delay=0.5

baseAngle=idle

# draw process
(
	while :
	do
		# eval $(cat "$drawfile")
		# [ "$MODEL" ] && draw "$MODEL"
		draw "$MODEL"
		sleep $delay
	done
) &
drawprocpid=$!

while :
do
	pipeval="$(cat "$tmpfile")"
	case "$pipeval" in
		angle*)
			baseAngle="${pipeval#* }"
			;;
		model*)
			MODEL="${pipeval#* }"
			initangles "$MODEL" 'base'
			;;
	esac
	set > "$drawfile"
done
