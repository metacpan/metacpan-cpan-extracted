#!/bin/zsh

set -e
setopt err_return
autoload colors;
[[ -t 1 ]] && colors

function warn { print 1>&2 -- $bg[red]$*$bg[default] }
function die { warn $@; return 1 }

progname=$0
function usage {
    cat <<EOF 1>&2
Usage: \$yl_scripts/${progname:t} [-n | -q] [--datadir=DIR] [--myapp=MyYATT] DESTDIR

This script will setup cgi-bin/runyatt.cgi and .htaccess in DESTDIR.
Short options:
  -n   dry run. Do not actually change any files; just print what would happen.
  -q   quiet.
Long options:
  --datadir[=DIR]   prepare secure data saving directory.
  --myapp[=MyYATT]   create mock MyYATT.pm in cgi-bin/runyatt.lib/MyYATT.pm.
EOF
    exit ${1:-0}
}


#========================================
# FindBin equivalent. (Depends on GNU readlink)
#========================================

# $checkout_dir/runyatt.lib/YATT/scripts
if [[ -L $0:h ]]; then
realbin=$(readlink -f $(cd $0:h && print $PWD))
else
realbin=$(cd $0:h && print $PWD)
fi

# $checkout_dir/runyatt.lib
libdir=$realbin:h:h

# $checkout_dir/runyatt
driver_path=$libdir:r

# runyatt
driver_name=$driver_path:t

#========================================
# Option parsing
#========================================

opt_spec=(
    h=o_help
    x=o_xtrace
    n=o_dryrun
    y=o_yn
    q=o_quiet
    Y=o_use_anyway

    --
    -myapp::
    -datadir::
    # -location
    '-document_root:=o_document_root'
    # -link_driver
    # -as:
)

zparseopts -D -A opts $opt_spec

if ! (($#o_use_anyway)); then
    cat 1>&2 <<EOF
Use of $0 is now $bg[red]deprecated$bg[default].
If you really want to use this, please specify -Y.
EOF
    exit 1
fi

if ((ARGC)) && [[ $1 == -* ]]; then
    warn "Unknown option '$1'"
    usage
fi

(($#o_help)) && usage

[[ -n $o_xtrace ]] && set -x
if [[ -z $o_quiet ]]; then o_verbose=(-v); else o_verbose=(); fi

((ARGC)) || usage

destdir=$1; shift

if [[ $destdir == . ]]; then
    destdir=$PWD
elif [[ $destdir != /* ]]; then
    destdir=$PWD/$destdir
fi

#========================================
# utils.
#========================================
function x {
    if [[ -z $o_quiet ]]; then
	print -- $bg[cyan]"$@"$bg[default]
    fi
    if [[ -z $o_dryrun ]]; then
	"$@"
    fi
}

function find_pat {
    perl -nle '
      BEGIN {$PAT = shift}
      if (/$PAT/) {print $1 and exit 0}
      elsif (eof) {print STDERR "Not found: $PAT\n"; exit 1}
' "$@"
}

function mkfile {
    zparseopts -D m:=mode
    if [[ -z $o_quiet ]]; then
	echo $bg[cyan]mkfile $1 "$bg[default] as:"
	echo "$bg[blue]#{{{{{{{{{{{{$bg[default]"
    fi
    if [[ -n $o_dryrun ]]; then
	cat
    elif [[ -n $o_quiet ]]; then
	cat > $1
    else
	tee $1
    fi
    if [[ -z $o_quiet ]]; then
	echo "$bg[blue]#}}}}}}}}}}}}$bg[default]"
    fi
    if [[ -n $mode ]]; then
	x chmod $o_verbose $mode[-1] $1
    fi
}

function confirm {
    local yn confirm_msg=$1 dying_msg=$2
    if [[ -n $o_dryrun || -n $o_yn ]]; then
	true
    elif [[ -t 0 ]]; then
	read -q "yn?$confirm_msg (Y/n) " || die Canceled.
    else
	die $dying_msg, exiting...
    fi
}

#========================================
# Env checking.
#========================================

if ! perl -le 'exit 1 if $] < 5.010'; then
    die Perl 5.010 or higher is required for YATT::Lite!
fi

if (($+commands[selinuxenabled])) && selinuxenabled; then
    is_selinux=1
else
    is_selinux=0
fi

#========================================
# apache config detection.
#========================================
# XXX: Should allow explicit option.

o_chmod_c=(-c)
CGI_BIN=cgi-bin
USER_DIR=public_html

if [[ $OSTYPE == darwin* ]]; then
    CGI_BIN=CGI-Executables
    USER_DIR=Sites
    o_chmod_c=()

    apache=/etc/apache2/httpd.conf
    document_root=$(find_pat '^DocumentRoot\s+"([^"]*)"' $apache) ||
    document_root=/Library/WebServer/Documents

    APACHE_RUN_GROUP=$(find_pat '^Group\s+(\S+)' $apache) ||
    APACHE_RUN_GROUP=www

elif [[ -r /etc/redhat-release ]]; then
    apache=/etc/httpd/conf/httpd.conf
    document_root=$(find_pat '^DocumentRoot\s+"([^"]*)"' $apache)
    APACHE_RUN_GROUP=$(find_pat '^Group\s+(\S+)' $apache)
elif [[ -r /etc/lsb-release ]] && source /etc/lsb-release; then
    case $DISTRIB_ID in
	(*Ubuntu*)

	apache=/etc/apache2/sites-available/default
	document_root=$(find_pat '^\s*DocumentRoot\s+"?([^"]*)"?' $apache)

	# for APACHE_RUN_GROUP
	source /etc/apache2/envvars
	if [[ -z $APACHE_RUN_GROUP ]]; then
	    die "Can't find APACHE_RUN_GROUP!"
	fi

	curgroups=($(id -Gn))
	if (($curgroups[(ri)$APACHE_RUN_GROUP] >= $#curgroups)); then
	    die User $USER is not a member of $APACHE_RUN_GROUP, stopped.
	fi
	;;
	(*)
	die "Unsupported distribution! Please modify $0 for $DISTRIB_ID"
	;;
    esac
else
    document_root=/var/www
    APACHE_RUN_GROUP=apache
fi

if (($#o_document_root)); then
    document_root=${o_document_root[2][2,-1]}
fi

if [[ -n $APACHE_RUN_GROUP ]] && (($+commands[groups])); then
    mygroups=($(groups))
    if (($mygroups[(ri)$APACHE_RUN_GROUP] > $#mygroups)); then
	warn "You are not a member of $APACHE_RUN_GROUP. To change this, do \"sudo usermod -aG $APACHE_RUN_GROUP $USER\" and re-login this server."
    fi
fi

#========================================
# destdir verification/preparation and location detection.
#========================================

if ! [[ -e $destdir ]]; then
    confirm "Do you wan to create a destination directory '$destdir' now?" \
	"Can't find destination directory '$destdir'!"

    x mkdir -p $destdir
elif ! [[ -d $destdir ]]; then
    confirm "Destination '$destdir',
you specified, is not a directory.
Do you want to use its parent '${destdir:h}',
instead?" \
	"destdir '$destdir' is not a directory!"

    destdir=$destdir:h
fi

if [[ $destdir = $document_root(|/*) ]]; then
    location=${destdir#$document_root}
    cgi_bin_perm=775
    install_type=sys
    cgi_bin=$destdir/$CGI_BIN
elif [[ $destdir = $HOME/$USER_DIR(|/*) ]]; then
    location=/~$USER${destdir#$HOME/$USER_DIR}
    cgi_bin_perm=755; # for suexec
    install_type=user
    cgi_bin=$destdir/cgi-bin
else
    die Can\'t extract URL from destdir=$destdir.
fi

#========================================
# Main.
#========================================
cgi_loc=$location/cgi-bin

if ! [[ -d $cgi_bin ]]; then
    x install -d $o_verbose -m 2$cgi_bin_perm $cgi_bin
else
    x chmod $o_chmod_c 2$cgi_bin_perm $cgi_bin
fi

# Create library directory and link yatt in it.
x mkdir -p $cgi_bin/$driver_name.lib
# XXX: httpd_${install_type}_htaccess_t
mkfile $cgi_bin/$driver_name.lib/.htaccess <<EOF
deny from all
EOF
x ln $o_verbose -nsf $driver_path.lib/YATT $cgi_bin/$driver_name.lib/YATT
mkfile $cgi_bin/.htaccess <<EOF
Options +ExecCGI -Indexes -Includes
EOF
x ln $o_verbose -nsf $driver_path.ytmpl $cgi_bin/

if (($is_selinux)); then
    # XXX: Only if user ownes original.
    # XXX: semanage fcontext -a -t $type
    x chcon -R -t httpd_${install_type}_content_t $driver_path.*(/) || true
fi

# Create custom DirHandler.
# XXX: only if missing.
if (($+opts[--myapp])); then
    # XXX: Must modify runyatt.cgi appns!
    myapp=${opts[--myapp][2,-1]:-MyYATT}
    mkfile -m a+x $cgi_bin/$driver_name.lib/$myapp.pm <<EOF
#!/usr/bin/perl -w
package $myapp; sub MY () {__PACKAGE__}
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin;
use lib \$FindBin::RealBin;

use YATT::Lite::WebMVC0::DirApp -as_base, qw(*YATT *CON Entity);

1;
EOF
fi

# Copy driver cgi and link fcgi.
x install -m $cgi_bin_perm $driver_path.cgi $cgi_bin/$driver_name.cgi
if (($is_selinux)); then
    x chcon $o_verbose -t httpd_${install_type}_script_exec_t $cgi_bin/$driver_name.cgi || true
fi
x ln $o_verbose -nsf $driver_name.cgi $cgi_bin/$driver_name.fcgi

# Prepare data saving directory.
# XXX: Should verify *NON* accessibility of this datadir.
if [[ -d $destdir/data ]] || (($+opts[--datadir])); then
    datadir=${opts[--datadir][2,-1]:-$destdir/data}
    if [[ -d $datadir ]]; then
	x chmod $o_verbose 2775 $datadir
	x chgrp $o_verbose $APACHE_RUN_GROUP $datadir
    else
	x install -m 2775 -g $APACHE_RUN_GROUP -d $datadir
    fi
    mkfile -m 644 $datadir/.htaccess <<<"deny from all"
    if (($is_selinux)); then
	x chcon $o_verbose -t httpd_${install_type}_script_rw_t $datadir
    fi

    if [[ -r $destdir/.htyattrc.pl ]]; then
	# XXX: This can fail second time, mmm...
	x $realbin/yatt.command -d $destdir --if_can setup
    fi
fi

# Then activate it!
if [[ -r $destdir/dot.htaccess ]]; then
    x cp $o_verbose $destdir/dot.htaccess $destdir/.htaccess
    x sed -i -e "s|@DRIVER@|$cgi_loc/$driver_name.cgi|" $destdir/.htaccess
else
    # Mapping *.ytmpl(private template) to x-yatt-handler is intentional.
    mkfile $destdir/.htaccess <<EOF
Action x-yatt-handler $cgi_loc/$driver_name.cgi
# Action x-yatt-handler $cgi_loc/$driver_name.fcgi
AddHandler x-yatt-handler .yatt .ytmpl .ydo

Options -Indexes -Includes -ExecCGI
DirectoryIndex index.yatt index.html

<Files *.ytmpl>
deny from all
</Files>
EOF
fi

if [[ -z $o_dryrun ]]; then
    echo $bg[green]OK$bg[default]: URL=http://localhost$location/
fi
