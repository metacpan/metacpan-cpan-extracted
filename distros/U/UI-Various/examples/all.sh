#!/bin/bash
#
# Run all examples one after another for one or all UIs:
#
# Author: Thomas Dorner
# Copyright (C) 2024-2024 by Thomas Dorner

readonly USAGE="usage:	${0##*/} {1|2|3|4|all}

	The examples know the following UIs:

	1	Tk
	2	Curses
	3	RichTerm
	4	PoorTerm"
[[ $# -lt 1 ]]  &&  echo "$USAGE"  &&  exit 1

declare uis=()
case $1 in
    [1234])		uis=("$1")	;;
    a|all|A|ALL)	uis=(1 2 3 4)	;;
    *)			echo "$USAGE"	;	exit 1
esac

declare examples=("${0%%/*}"/hello.pl "${0%%/*}"/hello-*.pl "${0%%/*}"/[los]*.pl)
declare example ui
for example in "${examples[@]}"; do
   for ui in "${uis[@]}"; do
       echo "===== running $example $ui ====="
       "$example" "$ui"
   done
done
