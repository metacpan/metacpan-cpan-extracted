#!/bin/zsh

set -e
setopt extendedglob

function die { echo 1>&2 $*; exit 1 }

function usage {
    cat 1>&2 <<EOF
Usage: ${0:t} [--cgi] [--app] /LOCATION

${0:t} is a command to generate Apache's .htaccess for you.
Please specify location (local part of URL) for current directory.

If --cgi option is given, this will also copy cgi-bin/runyatt.cgi for you.
If --app option is given, ../app.psgi is also copied.

Typically, if your DOCUMENT_ROOT is /var/www/html and
your contents are placed under /var/www/html/foo/bar,
location will be /foo/bar.
EOF

    exit 1
}


zparseopts -D -K -cgi=o_cgi -app=o_app || exit 1

((ARGC)) || usage

LOC=$1; shift

cgi=cgi-bin/runyatt.cgi

if (($#o_cgi)); then
    cgi_sample=$0:h/../samples/runyatt.cgi
    [[ -e $cgi_sample ]] || die "Can't find cgi sample: $cgi_sample"
    mkdir -p $cgi:h
    cp -v $cgi_sample $cgi

    cat <<EOF > $cgi:h/.htaccess
Options +ExecCGI -Indexes
EOF

fi

if (($#o_app)); then
    app_sample=$0:h/../samples/app.psgi
    [[ -e $cgi_sample ]] || die "Can't find cgi sample: $cgi_sample"
    cp -v $app_sample ../
fi

[[ -e $cgi ]] || die "Can't find cgi script: $cgi"

cat <<EOF | tee .htaccess
Action x-yatt-handler  $LOC/$cgi
AddHandler x-yatt-handler .yatt .ydo .ytmpl
DirectoryIndex index.yatt index.html
EOF
