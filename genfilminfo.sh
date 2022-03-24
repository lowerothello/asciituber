#!/bin/sh -e
# reflow the model headers to work with film reel support

[ "$1" ] || {
	echo 'missing argument: [$1 /path/to/model]'
	exit 1
}

find "$1" -name config | while IFS= read -r config
do
	firstlayer=
	for i in "${config%config}"*
	do
		[ "$firstlayer" ] || firstlayer="$i"
		:>_
		pointer=0
		while IFS= read -r line
		do
			pointer="$((pointer+1))"
			printf '%s\n' "$line" >>_
			[ "$pointer" -eq 3 ] && {
				echo 0 >>_
				echo 0 >>_
			}
		done < "$i"
		mv _ "$i"
	done
	echo "$(($(wc -l < "$firstlayer") - 5))" >> "$config"
done
