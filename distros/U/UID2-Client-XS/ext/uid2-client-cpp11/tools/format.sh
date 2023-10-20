#!/bin/bash -xe

echo "Usage $0 [ --fix ]"

if [ "$1" == "--fix" ]; then
	shift
	args=${@:-"--Werror"}
else
	args=${@:-"-n --Werror"}
fi


declare -a folders=(app include lib test)

for folder in "${folders[@]}"
do
	if [ ! -d "$folder" ]
	then
		echo "Can't find $folder, are you running this in the root of the project?"
		exit 1
	fi
done

if ! [ -x "$(command -v clang-format-14)" ]; then
	echo 'Error: clang-format-14 is not installed. Please run "sudo apt install clang-format-14".' >&2
	exit 1
fi

for folder in "${folders[@]}"
do
	find . \( -regex "\./$folder/.*\.\(cpp\|h\)" \) -print0 \
	  | xargs --null -n1 clang-format-14 -i $args
	echo ''
done

echo "Done."
