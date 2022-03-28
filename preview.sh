#!/bin/sh
# [$1 /path/to/model]
# Reads state from a named pipe
. ./asciituber.sh
. ./animations.sh

export MODEL="$1"
tmpfile=/tmp/$$
pipefile=/tmp/$$pipe # pipe watching process state dump
inputfile=/tmp/$$input # input process state dump, only contains relevant things
mkfifo "$tmpfile"
echo $$

trap 'kill $drawprocpid $pipewatchpid ; rm /tmp/$$* ; exit' int kill # clean up pipes & crocs

[ "$MODEL" ] && initangles "$MODEL" 'base'

# set this to the desired frametime (in seconds)
DELAY=0.05

export ANGLE=idle
export VIEW=current
export FRAME=1

# draw process
(
	while :
	do
		[ -f "$pipefile" ] && { # try to only set state once
			eval $(cat "$pipefile")
			rm "$pipefile"
		}
		[ -f "$inputfile" ] && {
			eval $(cat "$inputfile")
			rm "$inputfile"
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

(
	unset MODX
	unset MODY
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
		set > "$pipefile"
	done
) &
pipewatchpid=$!

# https://stackoverflow.com/a/46481173
escape_char="$(printf '\033')"

while :
do
	# these read calls are NOT posix
	read -rsn1 mode
	[ "$mode" == "$escape_char" ] && read -rsn2 mode
	case "$mode" in
		'[A') MODY=$((MODY + 1)) ;; # up
		'[B') MODY=$((MODY - 1)) ;; # dn
		'[C') MODX=$((MODX - 1)) ;; # lft
		'[D') MODX=$((MODX + 1)) ;; # rght
	esac
	# ideally this would be done atomically
	:>"$inputfile"
	echo "MODX=$MODX" >>"$inputfile"
	echo "MODY=$MODY" >>"$inputfile"

	# TODO: trigger a draw? or just compensate with high frame rate?
done
