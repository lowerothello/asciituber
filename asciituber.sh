#!/bin/sh -e
# a library, source this and use it's functions

# starting state
# --------------

# set to 1 to blink that eye
export LBLINK=0
export RBLINK=0

# user adjustable offset and trimming
# set AUTO to automatically centre
export AUTO= # 1
export X=1 # 1
export Y=0 # 0
export W=100 # 80
export H=48 # 24

# internal definitions
# mod offset, offsets the puppet
export MODX=0
export MODY=0
# the base angle to show
export baseAngle=idle
export eyelState=open
export eyerState=$eyelState
# the emote to show TODO: mixing 2+ emotes?
export EMOTE=idle

# functions
# ---------

# get the size of a frame
framewidth() { # [$1 /path/to/frame/0]
	fg= # dummy vars
	bg= # "
	attr= # "
	fheight= # "
	while IFS= read -r b # get state, nothing else
	do
		[ "$fg" ] || { fg=1; continue; }
		[ "$bg" ] || { bg=1; continue; }
		[ "$attr" ] || { attr=1; continue; }
		[ "$fheight" ] || { fheight=1; continue; }

		echo ${#b} # assume the top line of the ascii is full width
		break
	done < "$1"
}
frameheight() { # [$1 /path/to/frame/0]
	row= # dummy vars
	col= # "
	fheight= # NOT a dummy
	while IFS= read -r b # get state, nothing else
	do
		[ "$row" ] || { row=1; continue; }
		[ "$col" ] || { col=1; continue; }
		[ "$fheight" ] || { fheight="$b"; break; }
	done < "${1%/*}/config" # makes the assumption that the frame we're measuring is in context

	[ "$fheight" -gt 0 ] && {
		echo "$fheight"
	} || {
		echo "$(($(wc -l < "$1") - 5))"
	}
}

# min for 2 args
min2() {
	[ $1 -lt $2 ] && echo $1 || echo $2
}

# draw a block
drawblock() {
	./drawblock "$@"
}

# primitive way to work with floats in a language that doesn't support them
# Types:
# 1.) 0.XX0000 -> (XX * mod)
# 2.) X.X00000 -> (XX * mod)
float() { # [$1 float] [$2 modifier] [$3 type]
	negative=
	f="$1"
	case "$f" in
		"-"*)
			negative=1
			f="${f#-}"
	esac
	case "$3" in
		1)
			f="${f#??}" # trim first 2 chars
			f="$((${f#${f%%[!0]*}} * $2))" # multiply (leading zeroes confuse expr)
			f="${f%????}" # trim last 4 chars
			;;
		2)
			f="${f%???????}${f#??}" # remove the dot in the most roundabout way possible
			f="$((${f#${f%%[!0]*}} * $2))" # multiply (leading zeroes confuse expr)
			f="${f%?????}" # trim last 5 chars
			;;
		*)
			echo float: missing type
			exit 1
			;;
	esac
	[ "$negative" ] || f="-$f"
	[ "$f" == "-" ] || [ "$f" == "" ] && echo 0 || echo "$f"
}

# set the pos based on the root bone
# no z axis handling currently, not sure how to do it.
#   maybe the z axis should affect the y axis slightly? not sure.
setpos() { # [$1 x] [$2 y] [$3 z]
	# number chopping: 0.XX0000 -> (XX * 2)
	MODX=$(($(float "$1" 3 1) * -1))
	MODY=$(($(float "$2" 2 1) * -1))
}

# determine fallbacks for missing angles
# determine which angle files are available in idle/$prefix
# will set $prefix\Angle_$angle to it's fallback
# run once at the start for each needed prefix
initangles() { # [$1 /path/to/model] [$2 prefix]
	base="$1/idle/$2"
	[ -d "$base" ] || {
		echo "invalid model: missing idle/$2 directory" >&2
		exit 1
	}

	# EYES
	case "$2" in
		"eyel"|"eyer")
			# eye state fallbacks
			eval "$2State_open=open"
			[ -d "$base/half" ]    && eval "$2State_half=half"       || eval "$2State_half=open"
			[ -d "$base/closed" ]  && eval "$2State_closed=closed"   || eval "$2State_closed=\$$2State_half"
			# set the base for later
			base="$base/open"
			# eye look direction fallbacks
			lookbase="$base/idle"
			eval "$2Look_idle=idle"
			[ -d "$lookbase/up" ]     && eval "$2Look_up=up"         || eval "$2Look_up=idle"
			[ -d "$lookbase/dn" ]     && eval "$2Look_dn=dn"         || eval "$2Look_dn=idle"
			[ -d "$lookbase/lft" ]    && eval "$2Look_lft=lft"       || eval "$2Look_lft=idle"
			[ -d "$lookbase/rght" ]   && eval "$2Look_rght=rght"     || eval "$2Look_rght=idle"
			[ -d "$lookbase/upLft" ]  && eval "$2Look_upLft=upLft"   || eval "$2Look_upLft=\$$2Look_lft"
			[ -d "$lookbase/upRght" ] && eval "$2Look_upRght=upRght" || eval "$2Look_upRght=\$$2Look_rght"
			[ -d "$lookbase/dnLft" ]  && eval "$2Look_dnLft=dnLft"   || eval "$2Look_dnLft=\$$2Look_lft"
			[ -d "$lookbase/dnRght" ] && eval "$2Look_dnRght=dnRght" || eval "$2Look_dnRght=\$$2Look_rght"

	esac

	[ -d "$base/idle" ] || {
		echo "invalid model prefix: missing idle angle" >&2
		exit 1
	}

	# this block is nightmare fuel, no better way to put it.
	eval "$2Angle_idle=idle"
	[ -d "$base/up" ]             && eval "$2Angle_up=up"                         || eval "$2Angle_up=idle"
	[ -d "$base/dn" ]             && eval "$2Angle_dn=dn"                         || eval "$2Angle_dn=idle"
	[ -d "$base/lftS" ]           && eval "$2Angle_lftS=lftS"                     || eval "$2Angle_lftS=idle"
	[ -d "$base/lft" ]            && eval "$2Angle_lft=lft"                       || eval "$2Angle_lft=\$$2Angle_lftS"
	[ -d "$base/rghtS" ]          && eval "$2Angle_rghtS=rghtS"                   || eval "$2Angle_rghtS=idle"
	[ -d "$base/rght" ]           && eval "$2Angle_rght=rght"                     || eval "$2Angle_rght=\$$2Angle_rghtS"
	[ -d "$base/upLftS" ]         && eval "$2Angle_upLftS=upLftS"                 || eval "$2Angle_upLftS=\$$2Angle_lftS"
	[ -d "$base/upLft" ]          && eval "$2Angle_upLft=upLft"                   || eval "$2Angle_upLft=\$$2Angle_lft"
	[ -d "$base/upRghtS" ]        && eval "$2Angle_upRghtS=upRghtS"               || eval "$2Angle_upRghtS=\$$2Angle_rghtS"
	[ -d "$base/upRght" ]         && eval "$2Angle_upRght=upRght"                 || eval "$2Angle_upRght=\$$2Angle_rght"
	[ -d "$base/dnLftS" ]         && eval "$2Angle_dnLftS=dnLftS"                 || eval "$2Angle_dnLftS=\$$2Angle_lftS"
	[ -d "$base/dnLft" ]          && eval "$2Angle_dnLft=dnLft"                   || eval "$2Angle_dnLft=\$$2Angle_lft"
	[ -d "$base/dnRghtS" ]        && eval "$2Angle_dnRghtS=dnRghtS"               || eval "$2Angle_dnRghtS=\$$2Angle_rghtS"
	[ -d "$base/dnRght" ]         && eval "$2Angle_dnRght=dnRght"                 || eval "$2Angle_dnRght=\$$2Angle_rght"
	[ -d "$base/tltLft" ]         && eval "$2Angle_tltLft=tltLft"                 || eval "$2Angle_tltLft=idle"
	[ -d "$base/tltLftUp" ]       && eval "$2Angle_tltLftUp=tltLftUp"             || eval "$2Angle_tltLftUp=\$$2Angle_up"
	[ -d "$base/tltLftDn" ]       && eval "$2Angle_tltLftDn=tltLftDn"             || eval "$2Angle_tltLftDn=\$$2Angle_dn"
	[ -d "$base/tltLftLftS" ]     && eval "$2Angle_tltLftLftS=tltLftLftS"         || eval "$2Angle_tltLftLftS=\$$2Angle_lftS"
	[ -d "$base/tltLftLft" ]      && eval "$2Angle_tltLftLft=tltLftLft"           || eval "$2Angle_tltLftLft=\$$2Angle_tltLftLftS"
	[ -d "$base/tltLftRghtS" ]    && eval "$2Angle_tltLftRghtS=tltLftRghtS"       || eval "$2Angle_tltLftRghtS=\$$2Angle_rghtS"
	[ -d "$base/tltLftRght" ]     && eval "$2Angle_tltLftRght=tltLftRght"         || eval "$2Angle_tltLftRght=\$$2Angle_tltLftRghtS"
	[ -d "$base/tltLftUpLftS" ]   && eval "$2Angle_tltLftUpLftS=tltLftUpLftS"     || eval "$2Angle_tltLftUpLftS=\$$2Angle_tltLftLftS"
	[ -d "$base/tltLftUpLft" ]    && eval "$2Angle_tltLftUpLft=tltLftUpLft"       || eval "$2Angle_tltLftUpLft=\$$2Angle_tltLftUpLftS"
	[ -d "$base/tltLftUpRghtS" ]  && eval "$2Angle_tltLftUpRghtS=tltLftUpRghtS"   || eval "$2Angle_tltLftUpRghtS=\$$2Angle_tltLftRghtS"
	[ -d "$base/tltLftUpRght" ]   && eval "$2Angle_tltLftUpRght=tltLftUpRght"     || eval "$2Angle_tltLftUpRght=\$$2Angle_tltLftUpRghtS"
	[ -d "$base/tltLftDnLftS" ]   && eval "$2Angle_tltLftDnLftS=tltLftDnLftS"     || eval "$2Angle_tltLftDnLftS=\$$2Angle_tltLftLftS"
	[ -d "$base/tltLftDnLft" ]    && eval "$2Angle_tltLftDnLft=tltLftDnLft"       || eval "$2Angle_tltLftDnLft=\$$2Angle_tltLftDnLftS"
	[ -d "$base/tltLftDnRghtS" ]  && eval "$2Angle_tltLftDnRghtS=tltLftDnRghtS"   || eval "$2Angle_tltLftDnRghtS=\$$2Angle_tltLftRghtS"
	[ -d "$base/tltLftDnRght" ]   && eval "$2Angle_tltLftDnRght=tltLftDnRght"     || eval "$2Angle_tltLftDnRght=\$$2Angle_tltLftDnRghtS"
	[ -d "$base/tltRght" ]        && eval "$2Angle_tltRght=tltRght"               || eval "$2Angle_tltRght=idle"
	[ -d "$base/tltRghtUp" ]      && eval "$2Angle_tltRghtUp=tltRghtUp"           || eval "$2Angle_tltRghtUp=\$$2Angle_up"
	[ -d "$base/tltRghtDn" ]      && eval "$2Angle_tltRghtDn=tltRghtDn"           || eval "$2Angle_tltRghtDn=\$$2Angle_dn"
	[ -d "$base/tltRghtLftS" ]    && eval "$2Angle_tltRghtLftS=tltRghtLftS"       || eval "$2Angle_tltRghtLftS=\$$2Angle_lftS"
	[ -d "$base/tltRghtLft" ]     && eval "$2Angle_tltRghtLft=tltRghtLft"         || eval "$2Angle_tltRghtLft=\$$2Angle_tltRghtLftS"
	[ -d "$base/tltRghtRghtS" ]   && eval "$2Angle_tltRghtRghtS=tltRghtRghtS"     || eval "$2Angle_tltRghtRghtS=\$$2Angle_rghtS"
	[ -d "$base/tltRghtRght" ]    && eval "$2Angle_tltRghtRght=tltRghtRght"       || eval "$2Angle_tltRghtRght=\$$2Angle_tltRghtRghtS"
	[ -d "$base/tltRghtUpLftS" ]  && eval "$2Angle_tltRghtUpLftS=tltRghtUpLftS"   || eval "$2Angle_tltRghtUpLftS=\$$2Angle_tltRghtLftS"
	[ -d "$base/tltRghtUpLft" ]   && eval "$2Angle_tltRghtUpLft=tltRghtUpLft"     || eval "$2Angle_tltRghtUpLft=\$$2Angle_tltRghtUpLftS"
	[ -d "$base/tltRghtUpRghtS" ] && eval "$2Angle_tltRghtUpRghtS=tltRghtUpRghtS" || eval "$2Angle_tltRghtUpRghtS=\$$2Angle_tltRghtRghtS"
	[ -d "$base/tltRghtUpRght" ]  && eval "$2Angle_tltRghtUpRght=tltRghtUpRght"   || eval "$2Angle_tltRghtUpRght=\$$2Angle_tltRghtUpRghtS"
	[ -d "$base/tltRghtDnLftS" ]  && eval "$2Angle_tltRghtDnLftS=tltRghtDnLftS"   || eval "$2Angle_tltRghtDnLftS=\$$2Angle_tltRghtLftS"
	[ -d "$base/tltRghtDnLft" ]   && eval "$2Angle_tltRghtDnLft=tltRghtDnLft"     || eval "$2Angle_tltRghtDnLft=\$$2Angle_tltRghtDnLftS"
	[ -d "$base/tltRghtDnRghtS" ] && eval "$2Angle_tltRghtDnRghtS=tltRghtDnRghtS" || eval "$2Angle_tltRghtDnRghtS=\$$2Angle_tltRghtRghtS"
	[ -d "$base/tltRghtDnRght" ]  && eval "$2Angle_tltRghtDnRght=tltRghtDnRght"   || eval "$2Angle_tltRghtDnRght=\$$2Angle_tltRghtDnRghtS"
}

# set the angle based on the head bone
setangle() { # [$1 bone prefix] [$2-4 (explicit unused)] [$5 x] [$6 y] [$7 z] [$8 w (unused cos quaternions suck ass, like srsly fuck these thingsss)]
	pitch=$(float "$5" 1 1)
	yaw=$(float "$6" 1 1)
	roll=$(float "$7" 1 1)

	if           [ $roll -gt $TILTSLIGHT ];     then # roll to the left
		if       [ $pitch -gt $LOOKUP ];    then # pitch up
			if   [ $yaw -lt -$LOOKSIDEFAR ];    then eval "$1Angle=\$$1Angle_tltLftUpLft" # yaw far left
			elif [ $yaw -lt -$LOOKSIDESLIGHT ]; then eval "$1Angle=\$$1Angle_tltLftUpLftS" # yaw slight left
			elif [ $yaw -gt $LOOKSIDEFAR ];     then eval "$1Angle=\$$1Angle_tltLftUpRght" # yaw far right
			elif [ $yaw -gt $LOOKSIDESLIGHT ];  then eval "$1Angle=\$$1Angle_tltLftUpRghtS" # yaw slight right
			else                                 eval "$1Angle=\$$1Angle_tltLftUp" # yaw centre
			fi
		elif     [ $pitch -lt -$LOOKDN ];   then # pitch down
			if   [ $yaw -lt -$LOOKSIDEFAR ];    then eval "$1Angle=\$$1Angle_tltLftDnLft" # yaw far left
			elif [ $yaw -lt -$LOOKSIDESLIGHT ]; then eval "$1Angle=\$$1Angle_tltLftDnLftS" # yaw slight left
			elif [ $yaw -gt $LOOKSIDEFAR ];     then eval "$1Angle=\$$1Angle_tltLftDnRght" # yaw far right
			elif [ $yaw -gt $LOOKSIDESLIGHT ];  then eval "$1Angle=\$$1Angle_tltLftDnRghtS" # yaw slight right
			else                                 eval "$1Angle=\$$1Angle_tltLftDn" # yaw centre
			fi
		else                                     # pitch centre\$
			if   [ $yaw -lt -$LOOKSIDEFAR ];    then eval "$1Angle=\$$1Angle_tltLftLft" # yaw far left
			elif [ $yaw -lt -$LOOKSIDESLIGHT ]; then eval "$1Angle=\$$1Angle_tltLftLftS" # yaw slight left
			elif [ $yaw -gt $LOOKSIDEFAR ];     then eval "$1Angle=\$$1Angle_tltLftRght" # yaw far right
			elif [ $yaw -gt $LOOKSIDESLIGHT ];  then eval "$1Angle=\$$1Angle_tltLftRghtS" # yaw slight right
			else                                 eval "$1Angle=\$$1Angle_tltLft" # yaw centre
			fi
		fi

	elif         [ $roll -lt -$TILTSLIGHT ];    then # roll to the \$right
		if       [ $pitch -gt $LOOKUP ];    then # pitch up
			if   [ $yaw -lt -$LOOKSIDEFAR ];    then eval "$1Angle=\$$1Angle_tltRghtUpLft" # yaw far left
			elif [ $yaw -lt -$LOOKSIDESLIGHT ]; then eval "$1Angle=\$$1Angle_tltRghtUpLftS" # yaw slight left
			elif [ $yaw -gt $LOOKSIDEFAR ];     then eval "$1Angle=\$$1Angle_tltRghtUpRght" # yaw far right
			elif [ $yaw -gt $LOOKSIDESLIGHT ];  then eval "$1Angle=\$$1Angle_tltRghtUpRghtS" # yaw slight right
			else                                 eval "$1Angle=\$$1Angle_tltRghtUp" # yaw centre
			fi
		elif     [ $pitch -lt -$LOOKDN ];   then # pitch down
			if   [ $yaw -lt -$LOOKSIDEFAR ];    then eval "$1Angle=\$$1Angle_tltRghtDnLft" # yaw far left
			elif [ $yaw -lt -$LOOKSIDESLIGHT ]; then eval "$1Angle=\$$1Angle_tltRghtDnLftS" # yaw slight left
			elif [ $yaw -gt $LOOKSIDEFAR ];     then eval "$1Angle=\$$1Angle_tltRghtDnRght" # yaw far right
			elif [ $yaw -gt $LOOKSIDESLIGHT ];  then eval "$1Angle=\$$1Angle_tltRghtDnRghtS" # yaw slight right
			else                                 eval "$1Angle=\$$1Angle_tltRghtDn" # yaw centre
			fi
		else                                     # pitch centre\$
			if   [ $yaw -lt -$LOOKSIDEFAR ];    then eval "$1Angle=\$$1Angle_tltRghtLft" # yaw far left
			elif [ $yaw -lt -$LOOKSIDESLIGHT ]; then eval "$1Angle=\$$1Angle_tltRghtLftS" # yaw slight left
			elif [ $yaw -gt $LOOKSIDEFAR ];     then eval "$1Angle=\$$1Angle_tltRghtRght" # yaw far right
			elif [ $yaw -gt $LOOKSIDESLIGHT ];  then eval "$1Angle=\$$1Angle_tltRghtRghtS" # yaw slight right
			else                                 eval "$1Angle=\$$1Angle_tltRght" # yaw centre
			fi
		fi

	else                                         # roll centre
		if       [ $pitch -gt $LOOKUP ];    then # pitch up
			if   [ $yaw -lt -$LOOKSIDEFAR ];    then eval "$1Angle=\$$1Angle_upLft" # yaw far left
			elif [ $yaw -lt -$LOOKSIDESLIGHT ]; then eval "$1Angle=\$$1Angle_upLftS" # yaw slight left
			elif [ $yaw -gt $LOOKSIDEFAR ];     then eval "$1Angle=\$$1Angle_upRght" # yaw far right
			elif [ $yaw -gt $LOOKSIDESLIGHT ];  then eval "$1Angle=\$$1Angle_upRghtS" # yaw slight right
			else                                 eval "$1Angle=\$$1Angle_up" # yaw centre
			fi
		elif     [ $pitch -lt -$LOOKDN ];   then # pitch down
			if   [ $yaw -lt -$LOOKSIDEFAR ];    then eval "$1Angle=\$$1Angle_dnLft" # yaw far left
			elif [ $yaw -lt -$LOOKSIDESLIGHT ]; then eval "$1Angle=\$$1Angle_dnLftS" # yaw slight left
			elif [ $yaw -gt $LOOKSIDEFAR ];     then eval "$1Angle=\$$1Angle_dnRght" # yaw far right
			elif [ $yaw -gt $LOOKSIDESLIGHT ];  then eval "$1Angle=\$$1Angle_dnRghtS" # yaw slight right
			else                                 eval "$1Angle=\$$1Angle_dn" # yaw centre
			fi
		else                                     # pitch centre\$
			if   [ $yaw -lt -$LOOKSIDEFAR ];    then eval "$1Angle=\$$1Angle_lft" # yaw far left
			elif [ $yaw -lt -$LOOKSIDESLIGHT ]; then eval "$1Angle=\$$1Angle_lftS" # yaw slight left
			elif [ $yaw -gt $LOOKSIDEFAR ];     then eval "$1Angle=\$$1Angle_rght" # yaw far right
			elif [ $yaw -gt $LOOKSIDESLIGHT ];  then eval "$1Angle=\$$1Angle_rghtS" # yaw slight right
			else                                 eval "$1Angle=\$$1Angle_idle" # yaw centre
			fi
		fi
	fi
}

setblink() { # [$1 eye] [$2 value]
	# BLINKHALF BLINKFULL
	val="$(float "$2" 1 2)"
	if   [ $val -gt $BLINKFULL ]; then eval "$1State=\$$1State_closed"
	elif [ $val -gt $BLINKHALF ]; then eval "$1State=\$$1State_half"
	else                           eval "$1State=\$$1State_open"
	fi
}

# draw the current state
draw() { # [$1 /path/to/model] [ $2 frame (indexed from 1) ]
	frame="${2:-1}"
	# clear the screen
	printf "\033[2J\033[H"
	# draw the base
	# echo $baseAngle $baseAngle_upLftS
	export eyelAngle=idle # TODO: gen properly instead of hardcoding
	export eyerAngle=$eyelAngle
	export mouthState=closed
	[ "$AUTO" ] && {
		W=$(tput cols)
		H=$(tput lines)
		# for loop to enumerate the first text file
		for k in "$1/$EMOTE/base/$baseAngle/"[0-9]
		do
			X=$(((W - $(framewidth "$k")) / 2 - 1)) # 1: magic number, seems to line it up right
			Y=$(((H - $(frameheight "$k")) / 2))
			break
		done
	}
	[ -d "$1/$EMOTE/base/$baseAngle" ] \
		&& drawblock "$1/$EMOTE/base/$baseAngle" "$frame"
	[ "$SKIPEYES" ] || {
		[ -d "$1/$EMOTE/eyel/$eyelState/$baseAngle/$eyelAngle" ] \
			&& drawblock "$1/$EMOTE/eyel/$eyelState/$baseAngle/$eyelAngle" "$frame"
		[ -d "$1/$EMOTE/eyer/$eyerState/$baseAngle/$eyerAngle" ] \
			&& drawblock "$1/$EMOTE/eyer/$eyerState/$baseAngle/$eyerAngle" "$frame"
	}
	[ "$SKIPMOUTH" ] || {
		[ -d "$1/$EMOTE/mouth/$mouthState/$baseAngle" ] \
			&& drawblock "$1/$EMOTE/mouth/$mouthState/$baseAngle" "$frame"
	}
	printf "\033[${H};${W}H"
}
