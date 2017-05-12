#!/bin/zsh

# set -e
cd $0:h || exit 1
yl_scripts=../scripts
progname=$0

function warn { echo 1>&2 $* }
function die { echo 1>&2 $*; exit 1 }

zparseopts -D -A opts p=o_save_password -testdb:: -testuser:: || exit 1

if [[ ! -r .htdbpass && -n $o_save_password ]]; then
    testdb=${opts[--testdb][2,-1]:-test}
    testuser=${opts[--testuser][2,-1]:-${USER:-test}}
    print "(testdb=$testdb, testuser=$testuser)"
    print -n "Enter DB password for samples: "
    read -s pass
    cat > .htdbpass <<EOF
dbname: $testdb
dbuser: $testuser
dbpass: $pass
EOF

    print "DB password is saved in $PWD/.htdbpass"
fi

function cmd_setup {
    $yl_scripts/setup-min.zsh -q -C --setup $1/html
}

function cmd_cleanup {
    $yl_scripts/cleanup.zsh -y $1
}

function cmd_help {
    echo Usage: $progname:t subcmd opts...
    echo " Avaiable commands are:"
    for k in ${(k)functions}; do
        [[ $k == cmd_* ]] || continue
        print " " $k:s/cmd_//
    done
    exit ${1:-0}
}

if ((ARGC)); then
    cmd=$1; shift
else
    cmd=setup
fi
func=cmd_$cmd

if ! (($+functions[$func])); then
    warn "Unknown subcommand '$cmd'"
    cmd_help 1
fi

for f in **/t; do
    $func "$@" $f:h
done
