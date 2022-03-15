#!/bin/sh -e
# [$1 /path/to/model]
. ./drawlib.sh

model="$1"

initangles "$model" 'base'

angle() {
	baseAngle=$1 draw "$model"
	sleep $delay
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
	sleep $delay
}
leftrightrectify() {
	angle idle
	angle lftS
	angle lft
	angle lftS
	angle idle
	sleep $delay
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
	sleep $delay
}
upleftrightrectify() {
	angle up
	angle upLftS
	angle upLft
	angle upLftS
	angle up
	sleep $delay
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
	sleep $delay
}
dnleftrightrectify() {
	angle dn
	angle dnLftS
	angle dnLft
	angle dnLftS
	angle dn
	sleep $delay
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
	sleep $delay
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
	sleep $delay
}
updown() {
	angle up
	angle idle
	angle dn
	angle idle
	sleep $delay
}
simpletlt() {
	angle tltLft
	angle idle
	angle tltRght
	angle idle
	sleep $delay
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
	sleep $delay
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
	sleep $delay
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
	sleep $delay
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
	sleep $delay
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
	sleep $delay
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
	sleep $delay
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
	sleep $delay
}
tltupdown() {
	angle tltLftUp
	angle tltLft
	angle tltLftDn
	angle tltLft
	sleep $delay
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
	sleep $delay
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
	sleep $delay
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
	sleep $delay
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
	sleep $delay
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

delay=0.2

while :
do
	# tltupdown
	# simpletlt
	# smallspin
	# bigspin
	# tltdiagonal
	# tltdiagonal2
	# leftrightupdownrectify
	# upleftrightrectify
	# leftrightrectify
	# dnleftrightrectify
	# tltleftright
	# tltdnleftrightab
	# angle lftS
	SKIPEYES=
	upleftright
	leftright
	dnleftright
	SKIPEYES=1
	upleftright
	leftright
	dnleftright
done
