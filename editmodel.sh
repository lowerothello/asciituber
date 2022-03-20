#!/bin/sh -e
# A repl to make editing models easier

model="${1:?"missing arg [\$1 model]"}"
angle=idle
previewpid="$(pidof preview.sh)"
previewpid="${previewpid%% *}" # only get the first pid
printf 'connecting to %s..' "${previewpid:?"preview.sh not running"}"
echo "$angle" > /tmp/$previewpid

while :
do
	printf 'PS1 '
	read -r cmd argv
	case "$cmd" in
		a*) # set angle
			[ $argv ] || {
				echo "usage: angle "
				continue
			}
			angle="$argv"
			echo angle "$angle" > /tmp/$previewpid
			;;
		ex*) # exit
			exit "${argv:-0}"
			;;
		e*) # edit
			;;
	esac
done
