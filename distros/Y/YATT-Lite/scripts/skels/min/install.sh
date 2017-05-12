#!/bin/bash
# -*- coding: utf-8 -*-

set -e

function die {
    echo 1>&2 $*; exit 1
}

function x {
    echo "# $@"
    if [[ -n $YATT_DRYRUN ]]; then
	return
    fi
    "$@"
}

: ${YATT_SKEL:=min}

function setup {
    local yatt_url=$1 yatt_skel=$2 yatt_localrepo=$3

    [[ -r .git ]] || x git init

    [[ -d lib ]]  || x mkdir -p lib

    if perl_has YATT::Lite; then
	true; # nop
    elif (($use_symlink)); then
	x ln -vs $yatt_localrepo lib/YATT
    else 
	x git submodule add $yatt_url lib/YATT
	if [[ -z $cpanm ]]; then
	    echo "Can't find cpanm!"
	    echo "Please install dependencies with \"cpanm --installdeps .\" manually"
	else
	    (
		cd lib/YATT;
		if [[ -w $(dirname $cpanm) ]]; then
		    x cpanm --installdeps .
		else
		    x sudo cpanm --installdeps .
		fi
	    )
	fi
    fi

    x cp -va $yatt_skel/approot/* .
}

function perl_has {
    local m
    for m in $*; do
	perl -M$m -e0 >& /dev/null || return 1
    done
}

if ! $(which realpath >/dev/null 2>&1); then
    function realpath {
	local fn=$1
	if [[ $fn = /* ]]; then
	    echo $fn
	else
	    echo $(pwd)/$fn
	fi
	    
    }
fi

use_symlink=0

: skel="" repo=""
if [[ $0 != "bash" && -r $0 && -x $0 ]]; then
    skel=$(dirname $(realpath $0))
    repo=$(dirname $(dirname $(dirname $skel)))
fi

cpanm=$(which cpanm 2>/dev/null) || true

if ! [[ -n $repo && -d $repo ]]; then
    # assume remote installation.

    YATT_GIT_URL=${YATT_GIT_URL:-https://github.com/hkoba/yatt_lite.git}

    echo Using remote git $YATT_GIT_URL

    setup "$YATT_GIT_URL" lib/YATT/scripts/skels/$YATT_SKEL

else
    # assume we already have yatt repo

    YATT_GIT_URL=${YATT_GIT_URL:-$repo}

    echo Using local git $YATT_GIT_URL

    if [[ $1 = -s || $1 = -l ]]; then
	use_symlink=1
    fi
    setup "$YATT_GIT_URL" "$skel" "$repo"

fi
