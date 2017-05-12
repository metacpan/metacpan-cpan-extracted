#!/bin/sh

die () {
    echo "$*" >&2
    exit 1
}
doit () {
    echo "\$ $*" >&2
    $* || die "[ERROR:$?]"
}

# rdfe=t/example/index-e.rdf
# doit wget -O $rdfe~ http://www.kawa.net/rss/index-e.rdf
# [ -f $rdfe ] || touch $rdfe
# diff $rdfe $rdfe~ > /dev/null || doit /bin/mv -f $rdfe~ $rdfe
# /bin/rm -f $rdfe~
# 
# rdfj=t/example/index-j.rdf
# doit wget -O $rdfj~ http://www.kawa.net/index.rdf
# [ -f $rdfj ] || touch $rdfj
# diff $rdfj $rdfj~ > /dev/null || doit /bin/mv -f $rdfj~ $rdfj
# /bin/rm -f $rdfj~

egrep -v '^t/.*\.t$' MANIFEST > MANIFEST~
ls -t t/*.t | sort >> MANIFEST~
diff MANIFEST MANIFEST~ > /dev/null || doit /bin/mv -f MANIFEST~ MANIFEST
/bin/rm -f MANIFEST~

[ -f Makefile ] && doit make clean
[ -f META.yml ] || touch META.yml
doit perl Makefile.PL
doit make
doit make disttest

main=`grep 'lib/.*pm$' < MANIFEST | head -1`
[ "$main" == "" ] && die "main module is not found in MANIFEST"
doit pod2text $main > README~
diff README README~ > /dev/null || doit /bin/mv -f README~ README
/bin/rm -f README~

meta=`ls -t *-*.*/META.yml | head -1`
diff META.yml $meta > /dev/null || doit /bin/cp -f $meta META.yml

doit make dist
[ -d blib ] && doit /bin/rm -fr blib
[ -f pm_to_blib ] && doit /bin/rm -f pm_to_blib
[ -f Makefile ] && doit /bin/rm -f Makefile
[ -f Makefile.old ] && doit /bin/rm -f Makefile.old

ls -lt *.tar.gz | head -1
