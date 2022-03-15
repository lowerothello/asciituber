#!/bin/sh -e
# a shell "library". good luck. it's needed. trust me.

# starting state
# --------------

# set to 1 to blink that eye
LBLINK=0
RBLINK=0

# user adjustable offset and trimming
# set AUTO to automatically centre
AUTO=1
X=0
Y=0
W=80
H=24

# USED AND CHANGED INTERNALLY, NO TOUCHY TOUCHY
# mod offset, offsets the puppet
MODX=0
MODY=0
# the base angle to show
baseAngle=idle
# the emote to show TODO: mixing 2+ emotes?
EMOTE=idle

# functions
# ---------

# get the size of a frame
framewidth() { # [$1 /path/to/frame/0]
	fg= # dummy vars
	bg= # "
	attr= # "
	while IFS= read -r b # get state, nothing else
	do
		[ "$fg" ] || {
			fg="$b"
			continue
		}
		[ "$bg" ] || {
			bg="$b"
			continue
		}
		[ "$attr" ] || {
			attr="$b"
			continue
		}
		echo ${#b}
		break
	done < "$1"
}
frameheight() { # [$1 /path/to/frame/0]
	echo "$(wc -l "$1")" | while read -r c _
	do
		echo $((c - 3))
	done
}

# min for 2 args
min2() {
	[ $1 -lt $2 ] && echo $1 || echo $2
}

# draw a block
drawblock() { # [$1 /path/to/directory] [$2 debug line]
	[ -d "$1" ] || {
		# printf "\033[Hwarn: drawblock asked to draw nonexistent dir '%s'" "$1" >&2
		# printf "warn: drawblock asked to draw nonexistent dir '%s'" "$1" >&2
		return 0
	}
	log=
	row=
	col=

	# read the config file
	while IFS= read -r line
	do
		[ "$row" ] || {
			row="$line"
			lineno=$((row + Y + MODY))
			[ $lineno -gt $H ] && return # off the bottom fully
			continue
		}
		[ "$col" ] || {
			col="$line"
			[ $((col + X + MODX)) -gt $W ] && return # off the right side fully
			continue
		}
	done < "$1/config"

	for layer in "$1/"[0-9]
	do
		fg=
		bg=
		attr=

		{ # TODO: can this be done per dir instead of per layer?
			xpos=$((X + MODX + col))
			ltrim=0
			[ "$xpos" -le 0 ] && {
				ltrim=$(((xpos) * -1 + 1))
			}
		}

		while IFS= read -r line
		do
			[ "$fg" ] || { fg="$line"; continue; }
			[ "$bg" ] || { bg="$line"; continue; }
			[ "$attr" ] || { attr="$line"; continue; }

			[ "$lineno" -ge $H ] && break # finish before lines are drawn off screen, damage
			if [ "$lineno" -ge 1 ] # start when the lines being drawn are on screen, damage
			then
				# trim off the left side for damage
				[ $ltrim -gt 0 ] && {
					line="$(echo "$line" | cut -c $ltrim-)"
				}

				[ ${#line} -le 0 ] || { # damage for off the left
					# for trimming off the right side
					trimwidth=$(min2 $((${#line} + ltrim)) $((W - col - MODX)))
					# width mod in case we're trimming off the left side, clears 1 extra column cos the xpos is 0 instead of 1
					[ $xpos -lt 0 ] && trimwidth=$((trimwidth + xpos - 1))
					# print the block

					# a debug option, probably don't touch
					# in an ideal world everything would be drawn linewise, but it's buggy
					# true for charwise drawing  (complex but proper formatting and overlapping)
					# false for linewise drawing (simpler but inherent overwriting so no bgcol support)
					# set this to true unless it runs too slowly or smth and your model is super simple
					true && {
						# set the text formatting opts
						printf '\033[%sm\033[38;5;%sm\033[48;5;%sm' "$attr" "$fg" "$bg"
						# read -n isn't posix, the alternative to get single chars is dd which is worse
						strptr=0
						printf '%s' "$line" | while IFS= read -n1 char
						do
							strptr=$((strptr + 1))
							[ "$strptr" -gt "$trimwidth" ] && break
							[ "$char" = " " ] || {
								printf "\033[$((lineno));$((xpos + strptr))H%s" "$char"
							}
							:
						done
						# unset the text formatting opts
						printf '\033[m'
					} || {
						printf "\033[$((lineno));$((xpos + 1))H\033[%sm\033[38;5;%sm%.*s\n" "$attr" "$fg" "$trimwidth" "$line"
						# \033[${trimwidth}X # block clearing snippet, if required (needed before but it just doesn't anymore? not sure)
					}
				}
			fi
			lineno=$((lineno + 1))
			[ $log ] && [ $2 ] || { # debug printing
				log=1
				[ "$2" ] && {
					printf "\033[$((H + $2));1H%s" "$row $col"
				}
			}
		done < "$layer"
	done
	return 0
}

# primitive way to work with floats in a language that doesn't support them
# number chopping: 0.XX0000 -> (XX * mod)
float() { # [$1 float] [$2 mod]
	case "$1" in
		"-"*)
			f="${1#???}" # trim first 3 chars
			f="-$((${f#${f%%[!0]*}} * $2))"
			;;
		*)
			f="${1#??}" # trim first 2 chars
			f="$((${f#${f%%[!0]*}} * $2))"
			;;
	esac
	f="${f%????}"
	[ "$f" == "-" ] || [ "$f" == "" ] && echo 0 || echo "$f"
}

# set the pos based on the root bone
# no z axis handling currently, not sure how to do it.
#   maybe the z axis should affect the y axis slightly? not sure.
setpos() { # [$1 x] [$2 y] [$3 z]
	# number chopping: 0.XX0000 -> (XX * 2)
	MODX=$(($(float "$1" 3) * -1))
	MODY=$(($(float "$2" 2) * -1))
}

# determine fallbacks for missing angles
# determine which angle files are available in idle/base, and assume they are the wanted angles
# run once at the start
initangles() { # [$1 /path/to/model] [$2 prefix]
	base="$1/idle/$2"
	[ -d "$base" ] || {
		echo "invalid model: missing idle/$2 directory" >&2
		exit 1
	}
	[ -d "$base/idle" ] || {
		echo "invalid model: missing idle angle" >&2
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
	pitch=$(float "$5" 1)
	yaw=$(float "$6" 1)
	roll=$(float "$7" 1)
	# printf "\033[$H;1H%s\n" "$pitch $yaw $roll"

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

# draw the current state
draw() { # [$1 /path/to/model]
	# clear the screen
	printf "\033[2J\033[H"
	# draw the base
	# echo $baseAngle $baseAngle_upLftS
	eyelOpenness=open
	eyelAngle=idle
	eyerOpenness=$eyelOpenness
	eyerAngle=$eyelAngle
	[ "$AUTO" ] && {
		W=$(tput cols)
		H=$(tput lines)
		for k in "$1/$EMOTE/base/$baseAngle/"[0-9]
		do
			X=$(((W - $(framewidth "$k")) / 2 - 1)) # 1: magic number, lines it up right
			Y=$(((H - $(frameheight "$k")) / 2))
			break
		done
	}
	drawblock "$1/$EMOTE/base/$baseAngle" # base
	[ "$SKIPEYES" ] || {
		drawblock "$1/$EMOTE/eyel/$eyelOpenness/$baseAngle/$eyelAngle" # eyel
		drawblock "$1/$EMOTE/eyer/$eyerOpenness/$baseAngle/$eyerAngle" # eyer
	}
	printf "\033[${H};${W}H"

	# # draw the blinks
	# [ $LBLINK == 1 ] && drawblock < "$1/$EMOTE/eyel/eyel$eyelAngle\Closed"
	# [ $RBLINK == 1 ] && drawblock < "$1/$EMOTE/eyer/eyel$eyelAngle\Closed"
}
