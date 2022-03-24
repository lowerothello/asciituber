#!/bin/sh
# A repl to make editing models easier

. ./asciituber.sh

model="${1:?"missing arg [\$1 model]"}"
initangles "$model" 'base'

angle="$baseAngle_idle"
emote="idle"
previewpid="$(pidof preview.sh)"
[ "$previewpid" ] || {
	echo "preview window not running!"
	echo "run ./preview in another window and try again"
	exit 1
}
previewpid="${previewpid##* }" # only get the last pid, the first one is the draw proc
printf 'connecting to %s..\n' "${previewpid}"
echo "angle $angle" > /tmp/$previewpid
sleep 0.2
echo "model $model" > /tmp/$previewpid
sleep 0.2

while :
do
	printf 'angle [%s]: ' "$angle"
	read -r cmd argv
	case "$cmd" in
		a*) # set angle
			[ $argv ] || {
				echo "usage: angle [angle]"
				echo "       sets the angle to be edited"
				continue
			}
			eval "test \$baseAngle_$argv" \
				&& eval "angle=\$baseAngle_$argv" \
				|| printf 'invalid angle "%s"\n' "$argv"
			echo angle "$angle" > /tmp/$previewpid
			;;
		e*) # edit
			usage() {
				echo "usage: edit [type] [file]"
				echo "       use the format [type/ext] for extended types"
				echo "       opens angle [angle], type [type], file [file] with \$EDITOR"
				continue
			}
			case "$argv" in
				# error on nothing or if there's more than one space
				''|*' '*' '*) usage
			esac
			type="${argv% *}"
			file="${argv#* }"
			case "$type" in
				# error if there's a missing extended type
				"eyel"|"eyer"|"mouth") echo "missing extended type" ; usage
			esac
			${EDITOR:-vi} "$model/$emote/$type/$file"
			;;
		ex*) # exit
			exit "${argv:-0}"
			;;
		l*) # list
			usage() {
				echo "usage: list [type]"
				echo "       use the format [type/ext] for extended types"
				echo "       list the files present for type [type] and angle [angle]"
				continue
			}
			case "$argv" in
				# error on nothing or if there's a space
				''|*' '*) usage ;;
				# error if there's a missing extended type
				"eyel"|"eyer"|"mouth") echo "missing extended type" ; usage ;;
			esac
			command ls "$model/$emote/$type"
			;;
		v*) # view
			[ $argv ] || {
				echo "usage: view [view]"
				echo "       sets the view animation used by the preview"
				echo "       use 'current' to view the selected angle"
				echo "       see ./animations.sh for the available animated views"
				continue
			}
			# TODO: how to test that a view is in ./animations.sh?
			# eval "test \$baseAngle_$argv" \
			# 	&& eval "angle=\$baseAngle_$argv" \
			# 	|| printf 'invalid angle "%s"\n' "$argv"
			echo view "$argv" > /tmp/$previewpid
			;;
	esac
done
