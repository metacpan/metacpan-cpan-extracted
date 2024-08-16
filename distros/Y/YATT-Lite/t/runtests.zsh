#!/bin/zsh

# This is a test driver for YATT::Lite. Just run this without argument.
# This will apply ``prove'' to all *.t.
# Also, if you specify '-C' flag, Coverage will be gathered.

set -e
setopt extendedglob localoptions err_return

autoload colors;
[[ -t 1 ]] && colors
#
c_em[1]=$fg[blue]$bg[yellow]
c_off=$fg[default]$bg[default]

function warn { print 1>&2 -n -- $*; print 1>&2 $c_off }
function die { warn $@; return 1 }

# chdir to $DIST_ROOT
bindir=$(cd $0:h; print $PWD)
if [[ $bindir != */YATT/t ]] && [[ -d $bindir:h/_build/lib/YATT ]]; then
    distdir=$bindir:h
    libdir=$bindir:h/_build/lib
    has_lib_yatt=1
elif [[ $bindir == */YATT/t ]]; then
    distdir=$bindir:h
    libdir=$bindir:h:h
    has_lib_yatt=1
else
    distdir=$bindir:h
    has_lib_yatt=0; # or use $+libdir
fi

cd $distdir

print distdir=$distdir

optspec=(
    C=o_cover
    T=o_taint
    y=o_yn
    v=o_verbose
    'l+:=o_lib'
    -nosamples
    -samples
    -samples-with-absdir
    -noplenv
    -brew::
)

zparseopts -D -A opts $optspec || true

if (($+opts[--samples])); then
    # Test samples only.
    (($+libdir)) || die samples needs lib/YATT, sorry.

    if (($+opts[--samples-with-absdir])); then
	argv=($PWD/samples/**/t/*.t(*nN,@N))
    else
	argv=(samples/**/t/*.t(*nN,@N))
    fi

elif [[ -z $argv[(r)(*/)#*.t] ]]; then
    # If no **/*.t is specified:
    # To make relative path invocation happier.
    argv=(t/**/*.t(N))
    if (($+libdir)) && ((! $+opts[--nosamples])) && [[ -d samples ]]; then
	if (($+opts[--samples-with-absdir])); then
	    argv+=($PWD/samples/**/t/*.t(*nN,@N))
	else
	    argv+=(samples/**/t/*.t(*nN,@N))
	fi
    fi
fi

#========================================
# Auto dependency installation via plenv + cpanm + cpanfile
#========================================
plenv_exec=()

function confirm {
    local yn confirm_msg=$1 dying_msg=$2
    if [[ -n $o_yn ]]; then
	true
    elif [[ -t 0 ]]; then
	# (g::) is for \n expansion.
	read -q "yn?${(g::)confirm_msg}$c_off (Y/n) " || die "\n$bg[red]Canceled."
	print
    else
	die $dying_msg, exiting...
    fi
}

function cpanfile_modules {
    local cpanfile=$1 phases; shift
    if ((ARGC)); then
	phases=($argv)
    else
	phases=(runtime test)
    fi
    plenv exec perl -MModule::CPANfile -Mstrict -le '
      my %ignored = map {$_=>1} qw/perl/;
      my $req = Module::CPANfile->load(shift)->prereq_specs;
      print join "\n", grep {not $ignored{$_}} map {
         map {sort keys %$_} @{$req->{$_}}{qw/requires recommends/}
      } @ARGV
    ' $cpanfile $phases
}

function plenv_install_minimum {
    if ! plenv which cpanm >&/dev/null; then
	confirm "cpanm is not yet installed for plenv. $c_em[1]Install now?" \
	    "Can't run cpanm"
	plenv install-cpanm
	plenv which cpanm || exit 1
    fi
    local m minmods
    minmods=(
	Module::CPANfile
    )
    for m in $minmods; do
	plenv exec perl -M$m -e0 >&/dev/null || {
	    confirm "$m is not yet installed for plenv. $c_em[1]Install now?"\
               "Can't use $m"
	    plenv exec cpanm $m
	}
    done
}

function plenv_install_missings {
    local cpanfile=$1 missings wants
    missings=()
    wants=($(cpanfile_modules $cpanfile))
    if (($+o_cover)); then
	wants+=(Devel::Cover)
    fi
    local m
    for m in $wants; do
	plenv exec perldoc -ml $m >&/dev/null || missings+=($m)
    done
    if (($#missings)); then
        confirm "Following modules are not yet installed for plenv:\n----\n${(F)missings}\n----\n$c_em[1]Install (with plenv exec cpanm) now? "\
               "Can't use $m"

	plenv exec cpanm -n -f $missings
    fi
}

if ((! $+opts[--noplenv])) && (($+commands[plenv])) &&
    plenv which perl | grep plenv >/dev/null &&
    [[ -n $o_yn || -t 0 ]]
then
    # If you enabled plenv and either -y or has tty input
    plenv_exec=(plenv exec)
    unset PERL5LIB
    plenv_install_minimum
    plenv_install_missings $distdir/cpanfile; # cpanm --installdeps $distdir, with confirmation.
fi
#========================================

if (($+opts[--brew])); then
    PERL=${opts[--brew][2,-1]:-~/perl5/perlbrew/bin/perl}
fi

if (($+PERL)); then
    if [[ -d $PERL:h/lib ]]; then
	# For barely built perl.
	export PERL5LIB=$PERL:h/lib:$PERL5LIB
    fi
fi

$plenv_exec ${PERL:-perl} -v

typeset -T HARNESS_PERL_SWITCHES harness ' '
export HARNESS_PERL_SWITCHES

(($+DEBUG_YATT_REFCNT)) || export DEBUG_YATT_REFCNT=1

if [[ -n $o_taint ]]; then
    echo "[with taint check]"
    harness+=($o_taint)
else
    echo "[normal mode (no taint check)]"
fi

if [[ -n $o_cover ]]; then
    echo "[[Coverage mode]]"
    cover_db=$bindir/cover_db
    charset=utf-8

    ignore=(
	-ignore_re '^/usr/local/'
	-ignore_re '\.(?:t|yatt|ytmpl|ydo|htyattrc\.pl|psgi)$'
	-ignore_re '^My[A-Z]'
	-ignore_re '/t_'
	-ignore_re '^f\d+$'
    )
    for d in ${(s/:/)PERL5LIB}; do
	ignore+=(-ignore_re "^$d")
    done

    harness+=(-MDevel::Cover=-db,$cover_db,${(j/,/)ignore},+select,'^Lite')

    (($+libdir)) && harness+=(-I$libdir)

    if (($#o_lib)); then
	for o val in $o_lib; do
	    harness+=(-I$val)
	done
    fi
fi

if [[ -n $HARNESS_PERL_SWITCHES ]]; then
    print -R HARNESS_PERL_SWITCHES=$HARNESS_PERL_SWITCHES
fi

integer rc=0
if [[ -n $o_taint ]]; then
    $plenv_exec ${PERL:-perl} -MTest::Harness -e 'runtests(@ARGV)' $argv ||
	rc=$?
else
    $plenv_exec ${PERL:-perl} =prove $o_lib $o_verbose $argv ||
	rc=$?	
fi

: ${docroot:=/var/www/html}
if [[ -n $o_cover ]] && [[ -d $cover_db ]] &&
       ! (($+GITHUB_TOKEN))
then
    # ``t/cover'' is modified to accpet charset option.
    $plenv_exec $bindir/cover -charset $charset $ignore $cover_db

    if [[ $PWD == $docroot/* ]]; then

	chmod a+rx $cover_db $cover_db/**/*(/N)
	cat <<EOF > $cover_db/.htaccess
allow from localhost
DirectoryIndex coverage.html
AddHandler default-handler .html
AddType "text/html; charset=$charset" .html
EOF

	print Coverage URL: http://localhost${cover_db#$docroot}/
    elif (($+commands[xdg-open])); then
	xdg-open $cover_db/coverage.html
    fi
fi

exit $rc
