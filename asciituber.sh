#/bin/sh -e
# [$1 /path/to/model]
. ./drawlib.sh

PORT=39540
tmpfile=/tmp/$$

# angle thresholds, how sensitive the head angles are
LOOKUP=10
LOOKDN=5
LOOKSIDESLIGHT=5
LOOKSIDEFAR=20
TILTSLIGHT=8
# blink thresholds, how sensitive the eyelids are (0~12)
BLINKHALF=3
BLINKFULL=10

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
# draw process
(
	while :
	do
		# reset new state (shell is jank for this)
		eval $(cat "$tmpfile")
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
					setblink 'eyer' $argv
					;;
				'"Blink_R"')
					setblink 'eyel' $argv
					;;
			esac
			;;
		"/VMC/Ext/Blend/Apply")
			# dump new state (shell is jank for this)
			set > "$tmpfile"
			;;
	esac
done
