#!/bin/sh

die () {
    echo "$*" >&2
    exit 1
}
doit () {
    echo "\$ $*" >&2
    $* || die "[ERROR:$?]"
}

egrep -v '^t/.*\.t$' MANIFEST > MANIFEST~
ls t/*.t >> MANIFEST~
diff MANIFEST MANIFEST~ > /dev/null || doit /bin/mv -f MANIFEST~ MANIFEST
/bin/rm -f MANIFEST~

[ -f Makefile ] && doit make clean
doit perl Makefile.PL
doit make
doit make disttest

main=`grep version_from META.yml | cut -f 2 -d :`
[ "$main" == "" ] && die "version_from is not found in META.yml"
doit pod2text $main > README

doit make dist
doit /bin/rm -fr blib pm_to_blib

ls -lt *.tar.gz | head -1
