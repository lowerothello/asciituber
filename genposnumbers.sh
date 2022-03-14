#!/bin/sh -e
# add the proper header to bases

[ "$1" ] || {
	echo 'missing argument: [$1 /path/to/bases]'
	exit 1
}

list="baseDn \
	baseDnLft \
	baseDnLftS \
	baseIdle \
	baseLft \
	baseLftS \
	baseTltLft \
	baseTltLftDn \
	baseTltLftLft \
	baseTltLftUp \
	baseUp \
	baseUpLft \
	baseUpLftS"

for i in $list
do
	[ -f "$1/$i" ] && {
		printf '0\n0\n' | cat - "$1/$i" > _
		mv _ "$1/$i"
	}
done

./genbaseright.sh "$@"
