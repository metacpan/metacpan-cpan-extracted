#!/bin/zsh

set -e
setopt err_return
setopt extended_glob numeric_glob_sort

progname=$0:t

function warn { echo 1>&2 $* }
function die { warn $*; exit 1 }

#========================================

default_dir=/var/www/cgi-bin

#========================================

function runas {
    local user=$1; shift
    if [[ -n $user ]]; then
	sudo -u $user "$@"
    else
	"$@"
    fi
}

function cmd_install {
    local opts; zparseopts -D -A opts d: h u: g: x
    (($+opts[-h])) && cmd_help ${0//cmd_/}

    local destbase=${opts[-d]:-$default_dir}

    local repo
    if ((! ARGC)); then
	repo=//yatt-pm
    else
	repo=$1
	shift;
    fi

    integer instno=1
    if cmd_list -q -d $destbase; then
	# instno ИЁНа
	instno=$(cmd_current -n) || die "Can't detect current instno!"
	((instno++))
    fi

    local destroot=$destbase/$(cmd_instno2root $instno)
    local destdir=$destroot.libs

    (($+opts[-x])) && set -x

    # Assumption:
    # -: $destdir is protected.
    # -: current user is in devel group.
    #
    runas "$opts[-u]" install -d $destdir -g ${opts[-g]:-devel} -m 2775
    svk co $repo/web/cgi-bin $destdir/yatt-pm
    runas "$opts[-u]" ln -s $destdir/yatt-pm/yatt.cgi $destroot.cgi

    local libno=1 d
    for d in yatt-pm/yatt.lib $*; do
	ln -s $d $destdir/$libno-$d:t
	((libno++))
    done
}

function cmd_use-action {
    local dir current cgi;
    if ((ARGC)); then dir=$1; shift; else dir=.; fi
    current=$(cmd_current) || return 1
    cgi=${current#/var/www}.cgi

    cp =(perl -Mstrict -nle '
      our $CGI; BEGIN {
        $CGI = shift;
      }
      next if /\bx-yatt-handler\b/;
      print;
      END {
        print "Action x-yatt-handler $CGI";
	print "AddHandler x-yatt-handler .html";
      }
    ' $cgi $dir/.htaccess) $dir/.htaccess

    touch $dir/.htyattroot
}

function cmd_current {
    local opts; zparseopts -D -A opts d: h n
    (($+opts[-h])) && cmd_help ${0//cmd_/}

    local dir=$opts[-d];
    if [[ -z $dir ]]; then
	dir=$default_dir || return 1
    fi
    (($+yatt_insts)) || cmd_list -q -d $dir || return 1

    if ((! $+opts[-n])); then
	print ${yatt_insts[-1]}
    else
	local instno; instno=${${${yatt_insts[-1]}:t:r}#yatt-}
	print $instno
    fi
}

function cmd_instno2root {
    local instno=$1
    print yatt-$1
}

# yatt_insts=()
help[list]='[-d DEST_DIR]
List installed YATT driver directories.'
function cmd_list {
    local opts; zparseopts -D -A opts d: h q
    (($+opts[-h])) && cmd_help ${0//cmd_/}

    local dir=$opts[-d];
    if [[ -z $dir ]]; then
	dir=$default_dir || return 1
    fi
    yatt_insts=($dir/yatt-<1->.libs(/N:r))

    if (($+opts[-q])); then
	return $[$#yatt_insts == 0]
    elif (($#yatt_insts)); then
	print -c $yatt_insts
    else
	die No yatt driver is installed in \'$dir\'
    fi
}

function cmd_help {
    local opts; zparseopts -D -A opts e
    if ((!ARGC)); then
	echo Usage: $progname '[-d DIR] subcmd [args...]'
    elif (($+functions[help_$1])); then
	help_$1
    elif (($+help[$1])); then
	echo Usage: $1 $help[$1]
    fi

    # -e for error.
    exit $+opts[-e]
}

function help_commands {
    local fn c
    for fn in ${(ko)functions}; do
	[[ $fn == cmd_* ]] || continue
	c=${fn//cmd_/}
	echo -n "  $c"
	if (($+help[$c])); then
	    echo -n " - ${${(f)help[$c]}[2]}"
	fi
	echo
    done
}

#========================================
zparseopts -D -A opts h x c:

if (($+opts[-c])); then
    # To override config variables.
    source $opts[-c] || exit 1
fi

if (($+opts[-x])); then
    set -x
    unset 'opts[-x]'
fi

if ((ARGC)); then
    cmd=$1; shift
fi

if (($+opts[-h])); then
    cmd_help "$@"
elif ((!$+functions[cmd_$cmd])); then
    warn "No such command: $cmd"
    cmd_help -e
else
    cmd_$cmd "$@"
fi
