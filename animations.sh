#!/bin/sh -e
# a library, source this and use it's functions

# expects ./asciituber.sh to be sourced and initangles to have been run
# expects the following to be set in the environment:
# - $MODEL - the model to draw with
# - $DELAY - the time in seconds to wait between draws, the frametime

show() { # dumb way to draw an angle
	baseAngle="$1" draw "$MODEL" "$FRAME"
	# printf '\033[H%s' "$FRAME"
	sleep $DELAY
	FRAME="$((FRAME+1))"
}
angle() { # wrap show and try to show a new angle smartly
	export FRAME=1
	show "$1"
}

leftright() {
	angle idle
	angle lftS
	angle lft
	angle lftS
	angle idle
	angle rghtS
	angle rght
	angle rghtS
	angle idle
	sleep $DELAY
}
leftrightrectify() {
	angle idle
	angle lftS
	angle lft
	angle lftS
	angle idle
	sleep $DELAY
}
upleftright() {
	angle up
	angle upLftS
	angle upLft
	angle upLftS
	angle up
	angle upRghtS
	angle upRght
	angle upRghtS
	angle up
	sleep $DELAY
}
upleftrightrectify() {
	angle up
	angle upLftS
	angle upLft
	angle upLftS
	angle up
	sleep $DELAY
}
dnleftright() {
	angle dn
	angle dnLftS
	angle dnLft
	angle dnLftS
	angle dn
	angle dnRghtS
	angle dnRght
	angle dnRghtS
	angle dn
	sleep $DELAY
}
dnleftrightrectify() {
	angle dn
	angle dnLftS
	angle dnLft
	angle dnLftS
	angle dn
	sleep $DELAY
}
leftrightupdown() {
	angle lftS
	angle upLftS
	angle lftS
	angle dnLftS
	angle lftS

	angle lft
	angle upLft
	angle lft
	angle dnLft
	angle lft

	angle lftS
	angle upLftS
	angle lftS
	angle dnLftS
	angle lftS

	angle idle
	angle up
	angle idle
	angle dn
	angle idle

	angle rghtS
	angle upRghtS
	angle rghtS
	angle dnRghtS
	angle rghtS

	angle rght
	angle upRght
	angle rght
	angle dnRght
	angle rght

	angle rghtS
	angle upRghtS
	angle rghtS
	angle dnRghtS
	angle rghtS

	angle idle
	angle up
	angle idle
	angle dn
	angle idle
	sleep $DELAY
}
leftrightupdownrectify() {
	angle lftS
	angle upLftS
	angle lftS
	angle dnLftS
	angle lftS

	angle lft
	angle upLft
	angle lft
	angle dnLft
	angle lft

	angle lftS
	angle upLftS
	angle lftS
	angle dnLftS
	angle lftS

	angle idle
	angle up
	angle idle
	angle dn
	angle idle
	sleep $DELAY
}
updown() {
	angle up
	angle idle
	angle dn
	angle idle
	sleep $DELAY
}
simpletlt() {
	angle tltLft
	angle idle
	angle tltRght
	angle idle
	sleep $DELAY
}
smallspin() {
	angle lftS
	angle upLftS
	angle up
	angle upRghtS
	angle rghtS
	angle dnRghtS
	angle dn
	angle dnLftS
	angle lftS
	angle idle
	sleep $DELAY
}
bigspin() {
	angle lftS
	angle lft
	angle upLft
	angle upLftS
	angle up
	angle upRghtS
	angle upRght
	angle rght
	angle dnRght
	angle dnRghtS
	angle dn
	angle dnLftS
	angle dnLft
	angle lft
	angle lftS
	angle idle
	sleep $DELAY
}
diagonal() {
	angle dnLftS
	angle dnLft
	angle dnLftS
	angle idle
	angle upRghtS
	angle upRght
	angle upRghtS
	angle idle
	sleep $DELAY
}


# TLT
tltleftright() {
	angle tltLft
	angle tltLftLftS
	angle tltLftLft
	angle tltLftLftS
	angle tltLft
	angle tltLftRghtS
	angle tltLftRght
	angle tltLftRghtS
	angle tltLft
	sleep $DELAY
}
tltupleftright() {
	angle tltLftUp
	angle tltLftUpLftS
	angle tltLftUpLft
	angle tltLftUpLftS
	angle tltLftUp
	angle tltLftUpRghtS
	angle tltLftUpRght
	angle tltLftUpRghtS
	angle tltLftUp
	sleep $DELAY
}
tltdnleftright() {
	angle tltLftDn
	angle tltLftDnLftS
	angle tltLftDnLft
	angle tltLftDnLftS
	angle tltLftDn
	angle tltLftDnRghtS
	angle tltLftDnRght
	angle tltLftDnRghtS
	angle tltLftDn
	sleep $DELAY
}
tltleftrightupdown() {
	angle tltLftLftS
	angle tltLftUpLftS
	angle tltLftLftS
	angle tltLftDnLftS
	angle tltLftLftS

	angle tltLftLft
	angle tltLftUpLft
	angle tltLftLft
	angle tltLftDnLft
	angle tltLftLft

	angle tltLtfLftS
	angle tltLftUpLftS
	angle tltLftLftS
	angle tltLftDnLftS
	angle tltLftLftS

	angle tltLft
	angle tltLftUp
	angle tltLft
	angle tltLftDn
	angle tltLft

	angle tltLftRghtS
	angle tltLftUpRghtS
	angle tltLftRghtS
	angle tltLftDnRghtS
	angle tltLftRghtS

	angle tltLftRght
	angle tltLftUpRght
	angle tltLftRght
	angle tltLftDnRght
	angle tltLftRght

	angle tltLftRghtS
	angle tltLftUpRghtS
	angle tltLftRghtS
	angle tltLftDnRghtS
	angle tltLftRghtS

	angle tltLft
	angle tltLftUp
	angle tltLft
	angle tltLftDn
	angle tltLft
	sleep $DELAY
}
tltupdown() {
	angle tltLftUp
	angle tltLft
	angle tltLftDn
	angle tltLft
	sleep $DELAY
}
tltsmallspin() {
	angle tltLftLftS
	angle tltLftUpLftS
	angle tltLftUp
	angle tltLftUpRghtS
	angle tltLftRghtS
	angle tltLftDnRghtS
	angle tltLftDn
	angle tltLftDnLftS
	angle tltLftLftS
	angle tltLft
	sleep $DELAY
}
tltbigspin() {
	angle tltLftLftS
	angle tltLftLft
	angle tltLftUpLft
	angle tltLftUpLftS
	angle tltLftUp
	angle tltLftUpRghtS
	angle tltLftUpRght
	angle tltLftRght
	angle tltLftDnRght
	angle tltLftDnRghtS
	angle tltLftDn
	angle tltLftDnLftS
	angle tltLftDnLft
	angle tltLftLft
	angle tltLftLftS
	angle tltLft
	sleep $DELAY
}
tltdiagonal() {
	angle tltLftDnLftS
	angle tltLftDnLft
	angle tltLftDnLftS
	angle tltLft
	angle tltLftUpRghtS
	angle tltLftUpRght
	angle tltLftUpRghtS
	angle tltLft
	sleep $DELAY
}
tltdiagonal2() {
	angle tltLftDnRghtS
	angle tltLftDnRght
	angle tltLftDnRghtS
	angle tltLft
	angle tltLftUpLftS
	angle tltLftUpLft
	angle tltLftUpLftS
	angle tltLft
	sleep $DELAY
}

tltleftrightab() {
	angle idle
	angle tltLft
	angle idle
	angle lftS
	angle tltLftLftS
	angle lftS
	angle lft
	angle tltLftLft
	angle lft
	angle lftS
	angle tltLftLftS
	angle lftS
	angle idle
	angle tltLft
	angle idle
	angle rghtS
	angle tltLftRghtS
	angle rghtS
	angle rght
	angle tltLftRght
	angle rght
	angle rghtS
	angle tltLftRghtS
	angle rghtS
}
tltupleftrightab() {
	angle up
	angle tltLftUp
	angle up
	angle upLftS
	angle tltLftUpLftS
	angle upLftS
	angle upLft
	angle tltLftUpLft
	angle upLft
	angle upLftS
	angle tltLftUpLftS
	angle upLftS
	angle up
	angle tltLftUp
	angle up
	angle upRghtS
	angle tltLftUpRghtS
	angle upRghtS
	angle upRght
	angle tltLftUpRght
	angle upRght
	angle upRghtS
	angle tltLftUpRghtS
	angle upRghtS
}
tltdnleftrightab() {
	angle dn
	angle tltLftDn
	angle dn
	angle dnLftS
	angle tltLftDnLftS
	angle dnLftS
	angle dnLft
	angle tltLftDnLft
	angle dnLft
	angle dnLftS
	angle tltLftDnLftS
	angle dnLftS
	angle dn
	angle tltLftDn
	angle dn
	angle dnRghtS
	angle tltLftDnRghtS
	angle dnRghtS
	angle dnRght
	angle tltLftDnRght
	angle dnRght
	angle dnRghtS
	angle tltLftDnRghtS
	angle dnRghtS
}
