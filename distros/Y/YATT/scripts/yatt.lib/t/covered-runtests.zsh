#!/bin/zsh

# set -e

function die { echo 1>&2 $*; exit 1 }

function usage {
    die Usage: $0:t "[--db cover_db]" foo.t bar.t ...
}

function runtests {
    time perl -MTest::Harness -e 'runtests(@ARGV)' $*
}

#----------------------------------------
integer nocover=0

opt_bool=(
  -help    h
  -xtrace  x
  -nocover
  -add
)

opt_has_arg=(
  -db:
  -charset:
  -browser:
)


# zparseopts -K doesn't works for me in script. Why? (zsh-4.3.4)
# typeset -gA opts
# opts[--charset]=utf-8
# print opts=${(kvj/,/)opts}
zparseopts -D -A opts $opt_bool $opt_has_arg
# print opts=${(kvj/,/)opts}

if (($+opts[-x] || $+opts[--xtrace])); then
    set -x
fi

# Make sure $charset is visible later. But why I need this?
export charset=${${opts[--charset]#=}:-utf-8}

if ((ARGC)); then
    files=($*)
else
    cd $0:h
    files=(*.t(N))
fi

(($#files)) || usage

export HARNESS_PERL_SWITCHES
if ((!$+opts[-nocover])) {
    cover_opt=(
	-ignore /dev/null
	-ignore '^/usr/local'
    )

    # Additional opts are passed to test harness.
    while ((ARGC >= 2)) && [[ $1 = [+-]* ]]; do
	opts[$1]=$2
	cover_opt+=($1 $2)
	shift; shift;
    done

    if (($+opts[--db])) && [[ -n $opts[--db] ]]; then
	cover_opt+=(-db ${opts[--db]#=})
	cover_db_path=${opts[--db]#=}

    elif ((ARGC == 1)); then
        # If no db is specified and single file mode,
        # create specific db with same rootname.
	cover_db_path=$argv[1]:r.db
	opts[--db]=$cover_db_path
	cover_opt+=(-db $cover_db_path)
	
    else
	cover_db_path=cover_db
    fi

    HARNESS_PERL_SWITCHES=-MDevel::Cover=${(j/,/)cover_opt}
}

if [[ $cover_db_path != /* ]]; then
    cover_db_path=$PWD/$cover_db_path
fi

#----------------------------------------
if (($+opts[-h])) || (($+opts[-help])); then
    usage
fi

(($+db[--add])) || cover -delete $cover_db_path

runtests $files

# To avoid &#8249; and other annoying of CGI::escapeHTML.
perl -e 'use CGI; CGI::self_or_default()->charset(shift); do shift;' \
    "$charset" =cover $cover_db_path

chmod a+rx $cover_db_path $cover_db_path/**/*(/N)

if [[ -n $charset ]]; then
    cat <<EOF > $cover_db_path/.htaccess
allow from localhost
AddHandler default-handler .html
AddType "text/html; charset=$charset" .html
EOF
fi

if (($+opts[--browser])); then
    ${opts[--browser]#=} file://$cover_db_path/coverage.html
fi
