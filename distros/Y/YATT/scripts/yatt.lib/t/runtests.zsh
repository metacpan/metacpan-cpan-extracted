#!/bin/zsh

set -e

cd $0:h

if ((ARGC)); then
    files=("$@")
else
    files=(*.t(N))
fi

if (($+PERL)) && [[ -d $PERL:h/lib ]]; then
	export PERL5LIB=$PERL:h/lib:$PERL5LIB
fi
${PERL:-perl} -MTest::Harness -e 'runtests(@ARGV)' $files
