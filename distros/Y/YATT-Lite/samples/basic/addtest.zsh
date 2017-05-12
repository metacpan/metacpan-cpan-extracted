#!/bin/zsh

set -eu
setopt extendedglob

scriptname=$0:a
thisdir=$0:a:h
basetest=$thisdir/1

function die { echo 1>&2 $*; exit 1 }
function usage {
    cat 1>&2 <<EOF; exit
Usage: ${scriptname:t} [-h | -x]

Creates a new test directory.
By default, just print what it will do.
When -x is given, it really creates new dir.
EOF
}

#========================================
zparseopts -D x=o_execute h=o_help

function run {
    print -- $@
    if (($#o_execute)); then
	"$@"
    fi
}

if (($#o_help)); then
    usage
fi

if ! (($#o_execute)); then
    cat <<EOF
# Dry run mode. (Nothing will be changed.)

EOF
fi

#========================================

tests=($thisdir/<1->(N))

newdir=$thisdir/$[$#tests+1]

for f in $newdir/{html,extlib}; do
    run mkdir -p $f
done

run ln -vnsf ../../app.psgi $newdir/app.psgi

run $basetest/t/lntests.zsh $newdir/t

if (($#o_execute)); then
    echo
    echo CREATED: $newdir
fi
