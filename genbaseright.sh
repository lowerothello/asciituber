#/bin/sh
# Gen right facing bases by flipping the left facing ones
# Used to automirror all or part of the model

# Useful for the eyes, the mouth, and any symmetrical overlays
# like glasses.

[ "$1" ] || {
	echo 'missing argument [$1 /path/to/model]'
	exit 1
}

# get a line out of a multiline file
line() { # [$1 line] [3< multiline file]
	count=0
	while IFS= read -r line
	do
		count=$((count + 1))
		[ $count = "$1" ] && {
			echo "$line"
			break
		}
	done
}
# check if a line is present in a multiline file, and print the index
lineindex() { # [$1 str] [3< multiline file]
	count=0
	while IFS= read -r line
	do
		count=$((count + 1))
		[ "$line" = "$1" ] && {
			echo "$count"
			return
		}
	done
}

# ANGLES
all="idle
up
dn
lftS
lft
rghtS
rght
upLftS
upLft
upRghtS
upRght
dnLftS
dnLft
dnRghtS
dnRght
tltLft
tltLftUp
tltLftDn
tltLftLftS
tltLftLft
tltLftRghtS
tltLftRght
tltLftUpLftS
tltLftUpLft
tltLftUpRghtS
tltLftUpRght
tltLftDnLftS
tltLftDnLft
tltLftDnRghtS
tltLftDnRght
tltRght
tltRghtUp
tltRghtDn
tltRghtLftS
tltRghtLft
tltRghtRghtS
tltRghtRght
tltRghtUpLftS
tltRghtUpLft
tltRghtUpRghtS
tltRghtUpRght
tltRghtDnLftS
tltRghtDnLft
tltRghtDnRghtS
tltRghtDnRght"
left="lftS
lft
upLftS
upLft
dnLftS
dnLft
tltLft
tltLftUp
tltLftDn
tltLftLftS
tltLftLft
tltLftRghtS
tltLftRght
tltLftUpLftS
tltLftUpLft
tltLftUpRghtS
tltLftUpRght
tltLftDnLftS
tltLftDnLft
tltLftDnRghtS
tltLftDnRght"
right="rghtS
rght
upRghtS
upRght
dnRghtS
dnRght
tltRght
tltRghtUp
tltRghtDn
tltRghtRghtS
tltRghtRght
tltRghtLftS
tltRghtLft
tltRghtUpRghtS
tltRghtUpRght
tltRghtUpLftS
tltRghtUpLft
tltRghtDnRghtS
tltRghtDnRght
tltRghtDnLftS
tltRghtDnLft"

eyevariant="idle
up
dn
lft
rght
upLft
upRght
dnLft
dnRght"
eyestate="open
closedS
closed
wide"

# need to know the width of the model to mirror the eyes
modelwidth="$(tac "$1/idle/base/idle/0" | head -n1)"
modelwidth="${#modelwidth}"
echo modelwidth: $modelwidth

# bases
genelse() { # [$1 type]
	for i in $(seq 1 $(echo "$left" | wc -l))
	do
		l="$(echo "$left" | line $i)"
		r="$(echo "$right" | line $i)"

		[ -d "$e/$1/$l" ] || continue

		mkdir -p "$e/$1/$r"
		for k in "$e/$1/$l/"[0-9]
		do
			echo "$e/$1/$l/${k##*/} > $e/$1/$r/${k##*/}"
			rev "$e/$1/$l/${k##*/}" > "$e/$1/$r/${k##*/}"
		done
		cp "$e/$1/$l/config" "$e/$1/$r/config" # pos is unchanged for bases, just cp over
	done
}
# eyes
geneye() { # [$1 hosteye] [$2 targeteye] [$3 hostangles] [$4 targetangles]
	for vs in $eyestate
	do
		[ -d "$e/$1/$vs" ] || continue
		for vi in $eyevariant
		do
			# flip the names if necessary
			li="$(echo "$3" | lineindex "$vi")"
			[ "$li" ] && {
				vil="$(echo "$3" | line "$li")"
				vir="$(echo "$4" | line $li)"
			} || {
				vil="$vi"
				vir="$vi"
			}
			for i in $(seq 1 $(echo "$all" | wc -l))
			do
				# flip the names if necessary
				a="$(echo "$all" | line "$i")"
				li="$(echo "3" | lineindex "$a")"
				[ "$li" ] && {
					l="$(echo "$3" | line "$li")"
					r="$(echo "$4" | line $li)"
					# nameflip=1
				} || {
					l="$a"
					r="$a"
					# nameflip=0
				}
				
				[ -d "$e/$1/$vs/$l/$vil" ] || continue

				mkdir -p "$e/$2/$vs/$r/$vir"
				for k in "$e/$1/$vs/$l/$vil/"[0-9]
				do
					rev "$e/$1/$vs/$l/$vil/${k##*/}" > "$e/$2/$vs/$r/$vir/${k##*/}"
					width=$(framewidth "$e/$2/$vs/$r/$vir/${k##*/}")
					row=
					while IFS= read -r b # mutate the config
					do
						[ "$row" ] || {
							row="$b"
							continue
						}
						echo "$row"
						offset=2 # idk if this translates to other model widths or not (only tested with 35 for now)
						echo "$((modelwidth - b - width + offset))"
					done < "$e/$1/$vs/$l/$vil/config" > "$e/$2/$vs/$r/$vir/config"

					echo "$e/$1/$vs/$l/$vil/${k##*/} > $e/$2/$vs/$r/$vir/${k##*/} (bangle=$a:eangle=$vi:w=$width)"
				done
			done
		done
	done
}
genwrapper() { # [$1 type to gen]
	case "$1" in
		eyel) geneye eyel eyer "$left" "$right" ;;
		eyer) geneye eyer eyel "$right" "$left" ;;
		*)    genelse "$1" ;;
	esac
}

for e in "$1/"* # iterate over emotes
do
	[ -d "$e" ] || continue # skip regular files in the model root
	[ -f "$1/mirrorlist" ] && { # only mirror files in the mirror list
		while read -r d _
		do
			genwrapper "$d"
		done < "$1/mirrorlist"
	} || { # else exit and call it a success
		echo "missing mirrorlist, mirroring nothing!"
		exit 0
	}
done

echo done!
