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
Usage: \$yl_scripts/${progname:t} [-n | -q] DESTDIR

This script will setup cgi-bin/runyatt.cgi and .htaccess in DESTDIR.
Short options:
  -n   dry run. Do not actually change any files; just print what would happen.
  -q   quiet.
EOF
    exit ${1:-0}
}

#========================================

# $0 == lib/YATT/scripts/setup-min.zsh

# lib/YATT/scripts
scriptsdir=$(cd $0:h && print $PWD)

# lib
libdir=$scriptsdir:h:h

samplecgi=$libdir/YATT/samples/runyatt.cgi
sampletmpl=$libdir/YATT/ytmpl

driver_name=runyatt

#========================================

opt_spec=(
    h=o_help
    x=o_xtrace
    n=o_dryrun
    q=o_quiet
    C=o_clean
    -setup=o_try_setup
)

zparseopts -D -A opts $opt_spec

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

function find_pat {
    perl -nle '
      BEGIN {$PAT = shift}
      if (/$PAT/) {print $1 and exit 0}
      elsif (eof) {print STDERR "Not found: $PAT\n"; exit 1}
' "$@"
}

#========================================
# Env checking.
#========================================

if ! perl -le 'exit 1 if $] < 5.010'; then
    die Perl 5.010 or higher is required for YATT::Lite!
fi

o_chmod_c=(-c)
CGI_BIN=cgi-bin
USER_DIR=public_html
integer wo_apache=0

if [[ $OSTYPE == darwin* ]]; then
    CGI_BIN=CGI-Executables
    USER_DIR=Sites
    o_chmod_c=()

    apache=/etc/apache2/httpd.conf
    [[ -r $apache ]] || die "Can't find $apache!"

    document_root=$(find_pat '^DocumentRoot\s+"([^"]*)"' $apache) ||
    document_root=/Library/WebServer/Documents

    APACHE_RUN_GROUP=$(find_pat '^Group\s+(\S+)' $apache) ||
    APACHE_RUN_GROUP=www

elif [[ -r /etc/redhat-release ]]; then
    apache=/etc/httpd/conf/httpd.conf
    [[ -r $apache ]] || die "Can't find $apache!"
    document_root=$(find_pat '^DocumentRoot\s+"([^"]*)"' $apache)
    APACHE_RUN_GROUP=$(find_pat '^Group\s+(\S+)' $apache)
elif [[ -r /etc/lsb-release ]] && source /etc/lsb-release; then
    case $DISTRIB_ID in
	(*Ubuntu*)

	apache=/etc/apache2/sites-available/default
	if [[ -r $apache ]]; then
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
	else
	    # Fake settings when apache2 is not installed.
	    document_root=/var/www
	    APACHE_RUN_GROUP=nogroup
	    wo_apache=1
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
    if ((!wo_apache && UID != 0 && $mygroups[(ri)$APACHE_RUN_GROUP] > $#mygroups)); then
	warn "You are not a member of $APACHE_RUN_GROUP. To change this, do \"sudo usermod -aG $APACHE_RUN_GROUP $USER\" and re-login this server."
    fi
fi

if ((wo_apache)); then
    location=/
    cgi_bin_perm=755
    install_type=sys
    cgi_bin=$destdir/$CGI_BIN

elif [[ $destdir = $document_root(|/*) ]]; then
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

# SELinux check.
if (($+commands[selinuxenabled])) && selinuxenabled; then
    is_selinux=1
else
    is_selinux=0
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

x install -m $cgi_bin_perm $samplecgi $cgi_bin/$driver_name.cgi
if (($is_selinux)); then
    x chcon $o_verbose -t httpd_${install_type}_script_exec_t $cgi_bin/$driver_name.cgi || true
fi

dn=$cgi_bin/$driver_name.ytmpl
if ! [[ -e $dn ]]; then
    x ln $o_verbose -nsf $sampletmpl $dn
fi

x ln $o_verbose -nsf $driver_name.cgi $cgi_bin/$driver_name.fcgi

((wo_apache)) || mkfile $cgi_bin/.htaccess <<EOF
Options +ExecCGI
EOF

dn=$destdir/../var
if [[ -d $dn ]]; then
    dirs=($dn/*/tmp(/N))
    if (($#dirs && $#o_clean)); then
	rm -rf $dirs
    fi
    if (cd $dn && git rev-parse --is-inside-work-tree >/dev/null); then
        x git checkout $dn
    fi
    x chgrp -R $APACHE_RUN_GROUP $dn
    if (($#dirs && $#o_clean)); then
	mkdir -p $dirs
    fi
    if (($is_selinux)); then
	x chcon $o_verbose -R -t httpd_${install_type}_script_rw_t $dn
    fi
fi

if (($#o_try_setup)); then
    top_app=$destdir/html/.htyattrc.pl
    if [[ -r $top_app ]]; then
	# XXX: This can fail second time, mmm...
	x $realbin/yatt.command -d $top_app:h --if_can setup
    fi
fi

# Then activate it!
if ((wo_apache)); then
    ; #nop

elif [[ -r $destdir/dot.htaccess ]]; then
    x cp $o_verbose $destdir/dot.htaccess $destdir/.htaccess
    x sed -i -e "s|@DRIVER@|$cgi_loc/$driver_name.cgi|" $destdir/.htaccess
else
    # Mapping *.ytmpl(private template) to x-yatt-handler is intentional.
    mkfile $destdir/.htaccess <<EOF
Allow from all

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
