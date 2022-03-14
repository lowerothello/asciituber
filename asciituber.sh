#/bin/sh -e
# [$1 /path/to/model]
. ./drawlib.sh

PORT=39540
TMPFILE=/tmp/$$

# angle thresholds, how sensitive looking around is
LOOKUP=10
LOOKDN=5
LOOKSIDESLIGHT=5
LOOKSIDEFAR=20
TILTSLIGHT=8

# seconds each frame should be shown for
# use for "smoothing" and managing cpu usage by the draw thread
FRAMETIME=0.1


which oscdump >/dev/null || {
	cat << EOF

this program depends on oscdump!
it's usually shipped with liblo.
install it!

EOF
	exit 1
}

initangles "$1" 'base'
initangles "$1" 'base'
# draw thread
(
	while :
	do
		# reset new state (shell is jank for this)
		# TODO: remove the subshell? xargs doesn't like newlines
		eval $(cat "$TMPFILE")
		draw "$1"
		sleep $FRAMETIME
	done
) &
subshellpid=$!
trap "kill $subshellpid" int kill
# update thread
oscdump $PORT | while read -r timestamp address types arg1 argv
do
	case "$address" in
		"/VMC/Ext/Root/Pos")
			[ "$arg1" == '"root"' ] && {
				setpos $argv
			}
			;;
		"/VMC/Ext/Bone/Pos")
			case "$arg1" in
				'"Head"')
					setangle 'base' $argv
					;;
				'"LeftEye"')
					setangle 'eyel' $argv
					;;
				'"RightEye"')
					setangle 'eyer' $argv
					;;
			esac
			;;
		"/VMC/Ext/Blend/Val")
			case "$arg1" in
				'"Blink_L"')
					# TODO: not posix compliant
					argv="${argv::1}"
					[ "$argv" -eq 1 ] && RBLINK=1 || RBLINK=0
					;;
				'"Blink_R"')
					# TODO: not posix compliant
					argv="${argv::1}"
					[ "$argv" -eq 1 ] && LBLINK=1 || LBLINK=0
					;;
			esac
			;;
		"/VMC/Ext/Blend/Apply")
			# dump new state (shell is jank for this)
			set > "$TMPFILE"
			;;
	esac
done
