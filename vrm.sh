#/bin/sh -e
# [$1 /path/to/model]
. ./asciituber.sh

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

# set this to the desired frametime (in seconds)
DELAY=0.05

MODEL="$1"

# check requirements are present
which oscdump >/dev/null || {
	cat << EOF

this program depends on oscdump!
it's usually shipped with liblo.
install it!

EOF
	exit 1
}

[ -x "./drawblock" ] || ./make.sh || {
	cat << EOF

failed to build the c components!
make sure you have a working c compiler installed.
if you're not using gcc, try setting \$CC to the name of your compiler.

EOF
	exit 1
}

trap 'printf "\033[?25h"; kill $subshellpid' int kill
# hide the cursor
printf '\033[?25l'

initangles "$1" 'base'
initangles "$1" 'base'

# draw process
(
	while :
	do
		# update state
		eval $(cat "$tmpfile")
		draw
		sleep $DELAY
	done
) &
subshellpid=$!

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
			# dump state
			set > "$tmpfile"
			;;
	esac
done
