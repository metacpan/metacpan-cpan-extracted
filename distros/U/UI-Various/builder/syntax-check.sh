#!/bin/bash
#
# check syntax of all Perl modules:
#
# This is useful if an example fails during initialisation (in the call of
# "use UI::Various" in examples/_common.pl).
#
# Author: Thomas Dorner
# Copyright (C) 2022-2022 by Thomas Dorner

#########################################################################
# predefined constants:

readonly PERLC='perl -c -Ilib'

# text highlighting, see https://en.wikipedia.org/wiki/ANSI_escape_code#Colors:
readonly BGREEN="\x1b[1;38;5;34m"
readonly BRED="\x1b[1;31m"
readonly GREEN="\x1b[38;5;34m"
readonly RESET="\x1b[0m"

#########################################################################
# cd into module's root directory:
if [[ $0 == */* ]]; then
    dir=${0%/*}
else
    dir=$(pwd)
fi
cd "$dir"  ||  exit
cd ..  ||  exit

#########################################################################
# check each Perl module:
(
    # core and main module must be checked 1st as they must be included to
    # verify each other:
    $PERLC lib/UI/Various/core.pm  ||  exit
    $PERLC lib/UI/Various.pm  ||  exit
    (
	ls lib/UI/Various/*.pm
	ls lib/UI/Various/Compound/*.pm
	ls lib/UI/Various/{PoorTerm,RichTerm}/*.pm
	ls lib/UI/Various/{Curses,Tk}/*.pm
    ) | while read mod; do
	[[ $mod == */core.pm ]]  &&  continue
	$PERLC -M'UI::Various ({use => [], include=>"none"})' $mod
    done
) |& \
    sed --regexp-extended \
	--expression='/^Name "Storable::Eval" used only once: /d' \
	--expression='/^Name "Storable::Deparse" used only once: /d' \
	--expression="s/^(.* syntax OK)\$/$GREEN\\1$RESET/" \
	--expression="s/^(Subroutine [a-z_]+ redefined at.*)/$BGREEN\\1$RESET/" \
	--expression="s/^(.* line [1-9][0-9]*\\.)\$/$BRED\\1$RESET/"
