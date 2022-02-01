#!/bin/bash
#
# simple wrapper around dod-check.pl to filter working sub-tests:
#
# Author: Thomas Dorner
# Copyright (C) 2021-2022 by Thomas Dorner

#########################################################################
# predefined constants:

# text highlighting, see https://en.wikipedia.org/wiki/ANSI_escape_code#Colors:
readonly BGREEN="\x1b[1;38;5;34m"
readonly BORANGE="\x1b[1;38;5;208m"
readonly BRED="\x1b[1;31m"
readonly GREEN="\x1b[38;5;34m"
readonly RESET="\x1b[0m"

umask 0022

#########################################################################
# run dod-check.pl and filter output:
set -o pipefail
set -o errexit
time ${0%.sh}.pl "$@" |& \
    sed --regexp-extended \
	--expression='/^[\t ]+ok [1-9][0-9]* - /d' \
	--expression="s/^(.*not ok [1-9][0-9]*( - .*)?)\$/$BRED\1$RESET/" \
	--expression="s/^(ok [1-9][0-9]*( # .*)?)\$/$BORANGE\1$RESET/" \
	--expression="s/^(ok [1-9][0-9]*( - .*)?)\$/$BGREEN\1$RESET/" \
	--expression="s/^( +ok [1-9][0-9]*( - .*)?)\$/$GREEN\1$RESET/" \
	--expression="s/^(# Looks like you failed .*)\$/$BRED\1$RESET/"
if [[ -n "$*" ]]; then
    chmod --recursive --changes a+rX \
	  Build.PL Changes LICENSE META.json README.md \
	  builder cpanfile examples lib minil.toml t
    chmod --changes 444 UI-Various-[0-9].[0-9][0-9].tar.gz
fi
