#!/bin/sh
# $Id: build.sh,v 1.3 2005/04/12 04:06:50 stephens Exp $
set -x
ummf="../../bin/ummf"

rm -f tmon.out
rm -rf gen
#export UMMF_PERL="${UMMF_PERL:-perl} -MDevel::Profiler"
#export UMMF_PERL="${UMMF_PERL:-perl} -d:DProf"
$ummf -e Perl -o gen/perl OddNames.zuml

#export UMMF_PERL="${UMMF_PERL:-perl} -d"
PERL5LIB="`$ummf --perl5lib`"
export PERL5LIB="$HOME/local/src/tangram/t2/perl/blib/lib:$PERL5LIB"

perl -I gen/perl -MEx2::Class_With_Spaces -MEx2::Class_with_dashes -e 'exit'

$ummf -e Java -o gen/java OddNames.zuml
javac -d gen/java `find gen -name '*.java'`


