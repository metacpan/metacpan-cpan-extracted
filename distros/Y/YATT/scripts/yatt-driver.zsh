#!/bin/zsh

set -e
setopt err_return
setopt extended_glob numeric_glob_sort

progname=$0:t

function warn { echo 1>&2 $* }
function die { warn $*; exit 1 }

#========================================

typeset -A default_dir
default_dir=(
    linux   /var/www/cgi-bin
    darwin  /Library/WebServer/CGI-Executables
)

yatt_sf=https://yatt-pm.svn.sourceforge.net/svnroot
yatt_bb=https://buribullet.net/svn

typeset -A repository
repository=(
  stable $yatt_sf/yatt-pm/trunk/yatt-pm/web
  devel  $yatt_bb/yatt-pm/web
)

#========================================
typeset -A help

help[install]='[-d DEST_DIR] [-u USER] [-n] [//stable | //devel | URL]
Install YATT from Subversion repository.
 -u $USER -- use sudo -u USER
 -d $DIR  -- Create yatt-$N.instd in $DIR.
'
function cmd_install {
    local opts; zparseopts -D -A opts d: h u: n
    (($+opts[-h])) && cmd_help ${0//cmd_/}

    local destdir; destdir=$(cmd_destdir $opts[-d]) || return 1

    local repo
    if ((! ARGC)); then
	repo=$repository[stable]
    elif [[ $1 = //[a-z]# ]]; then
	repo=$repository[${1#//}]
	shift;
    else
	# Ok?
	repo=$1
	shift;
    fi

    integer instno=1
    if cmd_list -q -d $destdir; then
	# instno ИЁНа
	instno=$(cmd_current) || die "Can't detect current instno!"
	((instno++))
    fi

    local command; command=(
        svn co $repo/cgi-bin $destdir/$(cmd_instno2dir $instno)
    )

    if (($+opts[-u])); then
	command=(sudo -u $opts[-u] $command)
    fi

    if (($+opts[-n])); then
	print $command
    elif ((! $+opts[-u])) && [[ ! -w $destdir ]]; then
	die "Destdir is not writable: '$destdir'"
    else
	$command
    fi
}

function cmd_use-cgi {
    
}

function cmd_current {
    local opts; zparseopts -D -A opts d: h
    (($+opts[-h])) && cmd_help ${0//cmd_/}

    (($+yatt_insts)) || cmd_list -q -d $opts[-d] || return 1

    local instno; instno=${${${yatt_insts[-1]}:t:r}#yatt-}
    print $instno
}

function cmd_instno2dir {
    local instno=$1
    print yatt-$1.instd
}

# yatt_insts=()
help[list]='[-d DEST_DIR]
List installed YATT instance directories.'
function cmd_list {
    local opts; zparseopts -D -A opts d: h q
    (($+opts[-h])) && cmd_help ${0//cmd_/}

    local dir=$opts[-d];
    if [[ -z $dir ]]; then
	dir=$(cmd_destdir) || return 1
    fi
    yatt_insts=($dir/yatt-<1->.instd(/N))

    if (($+opts[-q])); then
	return $[$#yatt_insts == 0]
    elif (($#yatt_insts)); then
	print -c $yatt_insts
    else
	die No yatt instance is installed in \'$dir\'
    fi
}

function cmd_destdir {
    local dir=$1 arch
    if [[ -z $dir ]]; then
	arch=${OSTYPE//-*/}
	(($+default_dir[$arch])) || die "Unknown architecture! $arch"\
	  $'\n Please specify -d DESTDIR'
	dir=$default_dir[$arch]
    fi

    [[ -d $dir ]] || die "No such destdir: $dir"

    cd $dir

    # To get absolute dirname.
    print $PWD
}

function cmd_latest {
    local opts; zparseopts -D -A opts d: h
    (($+opts[-h])) && cmd_help ${0//cmd_/}

    local match
    match=($(cmd_list ${(kv)opts})) || return 1
    print $match[-1]
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
    cmd_$cmd ${(kv)opts} "$@"
fi
