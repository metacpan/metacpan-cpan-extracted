#!/bin/sh

NAME="Text-Smart-Plugin"

set -e

# Make things clean.

make -k realclean ||:
rm -rf MANIFEST blib

PERL5LIB=`perl -e 'use Config; my $dir = $Config{sitelib}; $dir =~ s,$Config{siteprefix},$ENV{AUTOBUILD_INSTALL_ROOT},; print $dir'`
export PERL5LIB

# Make makefiles.
perl Makefile.PL PREFIX=$AUTOBUILD_INSTALL_ROOT
make manifest
echo $NAME.spec >> MANIFEST

# Build the RPM.
make

if [ -z "$USE_COVER" ]; then
  perl -MDevel::Cover -e '' 1>/dev/null 2>&1 && USE_COVER=1 || USE_COVER=0
fi

if [ -z "$SKIP_TESTS" -o "$SKIP_TESTS" = "0" ]; then
  if [ "$USE_COVER" = "1" ]; then
    cover -delete
    HARNESS_PERL_SWITCHES=-MDevel::Cover make test
    cover
    mkdir blib/coverage
    cp -a cover_db/*.html cover_db/*.css blib/coverage
    mv blib/coverage/coverage.html blib/coverage/index.html
  else
    make test
  fi
fi

make install

rm -f $NAME-*.tar.gz
make dist

if [ -f /usr/bin/rpmbuild ]; then
  rpmbuild -ta --clean $NAME-*.tar.gz
fi


