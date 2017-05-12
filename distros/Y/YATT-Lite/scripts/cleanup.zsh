#!/bin/zsh

set -e
setopt err_return
function die { echo 1>&2 $*; return 1 }

autoload colors
colors

setopt extendedglob

zparseopts -D y=o_yn n=o_dryrun || exit 1

o_verbose=()
(($#o_yn)) || o_verbose=(-v)

function confirm {
    local yn confirm_msg=$1 dying_msg=$2
    if [[ -n $o_dryrun || -n $o_yn ]]; then
	true
    elif [[ -t 0 ]]; then
	read -q "yn?$confirm_msg (Y/n) " || die " ..canceled."
	print
    else
	die $dying_msg, exiting...
    fi
}

if ((ARGC)); then
    cd $1
fi

# XXX: How about runyatt.psgi?
files=(
    html/cgi-bin/runyatt.*(@N)
    html/cgi-bin/runyatt.(cgi|fcgi|psgi)(N)
    html/cgi-bin/runyatt.lib/YATT(@N)
    html/cgi-bin/runyatt.lib/.htaccess(N)
    html/cgi-bin/.htaccess(N)
    html/.htaccess(N)
)

vars=(
    var/tmp(N)
)

myapp=(
    html/cgi-bin/runyatt.lib/*.pm(.N)
)

all=($files $vars)
if ! (($#myapp)); then
    all+=(html/cgi-bin)
fi

(($#o_yn)) || {
    print Deleting following files:
    print -c "  $PWD"/$^all
}

confirm "Are you sure to $bg[red]delete$bg[default] these?"

rm -f $o_verbose $files

if (($#vars)); then
    rm -rf $o_verbose $vars
    mkdir -p $vars
fi

if ! (($#myapp)); then
    rm -rf $o_verbose html/cgi-bin
fi

print Now cleaned-up: $PWD
