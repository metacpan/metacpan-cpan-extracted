#!/bin/sh

# my-deb.sh -- make .deb

# Copyright 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2017, 2018, 2019, 2020 Kevin Ryde

# my-deb.sh is shared by several distributions.
#
# my-deb.sh is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# my-deb.sh is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  If not, see <http://www.gnu.org/licenses/>.


# warnings::unused broken by perl 5.14, so use 5.10 for checks

set -e
set -x

DISTNAME=`sed -n 's/^DISTNAME = \(.*\)/\1/p' Makefile`
if test -z "$DISTNAME"; then
  echo "DISTNAME not found"
  exit 1
fi
echo "DISTNAME   $DISTNAME"

VERSION=`sed -n 's/^VERSION = \(.*\)/\1/p' Makefile`
if test -z "$VERSION"; then
  echo "VERSION not found"
  exit 1
fi
echo "VERSION    $VERSION"

DISTVNAME=`sed -n 's/^DISTVNAME = \(.*\)/\1/p' Makefile`
if test -z "$DISTVNAME"; then
  echo "DISTVNAME not found"
  exit 1
fi
DISTVNAME=`echo "$DISTVNAME" | sed "s/[$][(]VERSION[)]/$VERSION/"`
DISTVNAME=`echo "$DISTVNAME" | sed "s/[$][(]DISTNAME[)]/$DISTNAME/"`
echo "DISTVNAME  $DISTVNAME"

XS_FILES=`sed -n 's/^XS_FILES = \(.*\)/\1/p' Makefile`
EXE_FILES=`sed -n 's/^EXE_FILES = \(.*\)/\1/p' Makefile`

if test "$DISTNAME" = pngtextadd -o "$DISTNAME" = x2gpm
then DPKG_ARCH=`dpkg --print-architecture`
elif test -n "$XS_FILES"
then DPKG_ARCH=`dpkg --print-architecture`
else DPKG_ARCH=all
fi
echo "DPKG_ARCH  $DPKG_ARCH"

# programs named after the dist, libraries named with "lib"
# gtk2-ex-splash and wx-perl-podbrowser programs are lib too though
DEBNAME=`echo $DISTNAME | tr A-Z a-z`
DEBNAME=`echo $DEBNAME | sed 's/app-//'`
IS_PERL_LIB=0
if test -f Makefile.PL; then     # Perl modules
  IS_PERL_LIB=1
fi
if test -n "$EXE_FILES"; then    # Perl programs
  IS_PERL_LIB=0
fi
case $DISTNAME in
  # these have EXE_FILES programs but still named lib...-perl
  Gtk2-Ex-Splash|Wx-Perl-PodBrowser)
    IS_PERL_LIB=1 ;;
esac
if test $IS_PERL_LIB = 1; then
  DEBNAME="lib${DEBNAME}-perl"
fi
echo "DEBNAME    $DEBNAME"

DEBVNAME="${DEBNAME}_$VERSION-0.1"
DEBFILE="${DEBVNAME}_$DPKG_ARCH.deb"
echo "DEBVNAME   $DEBVNAME"
echo "DEBFILE    $DEBFILE"

# ExtUtils::MakeMaker 6.42 of perl 5.10.0 makes "$(DISTVNAME).tar.gz" depend
# on "$(DISTVNAME)" distdir directory, which is always non-existent after a
# successful dist build, so the .tar.gz is always rebuilt.
#
# So although the .deb depends on the .tar.gz don't express that here or it
# rebuilds the .tar.gz every time.
#
# The right rule for the .tar.gz would be to depend on the files which go
# into it of course ...
#
# DISPLAY is unset for making a deb since under fakeroot gtk stuff may try
# to read config files like ~/.pangorc from root's home dir /root/.pangorc,
# and that dir will be unreadable by ordinary users (normally), provoking
# warnings and possible failures from nowarnings().
#

test -f $DISTVNAME.tar.gz || make $DISTVNAME.tar.gz
debver="`dpkg-parsechangelog -c1 | sed -n -r -e 's/^Version: (.*)-[0-9.]+$/\1/p'`"
echo "debver $debver", want $VERSION
test "$debver" = "$VERSION"

rm -rf $DISTVNAME
tar xfz $DISTVNAME.tar.gz
unset DISPLAY; export DISPLAY
cd $DISTVNAME

if test -d examples; then
  if ! grep _examples debian/rules; then
    echo "examples directory not in debian/rules"
  fi
fi

dpkg-checkbuilddeps debian/control
fakeroot debian/rules binary

cd ..
rm -rf $DISTVNAME

#------------------------------------------------------------------------------
# source .dsc

cp $DISTVNAME.tar.gz ${DEBNAME}_$VERSION.orig.tar.gz
tar xfz ${DEBNAME}_$VERSION.orig.tar.gz
if test "$DISTVNAME" != "$DEBNAME-$VERSION"; then
  mv -T $DISTVNAME $DEBNAME-$VERSION
fi
dpkg-source -b $DEBNAME-$VERSION ${DEBNAME}_$VERSION.orig.tar.gz
rm -rf $DEBNAME-$VERSION

#------------------------------------------------------------------------------
# lintian .deb and source

lintian -I -i \
  --suppress-tags new-package-should-close-itp-bug,desktop-entry-contains-encoding-key,command-in-menu-file-and-desktop-file,emacsen-common-without-dh-elpa,bugs-field-does-not-refer-to-debian-infrastructure \
  ${DEBNAME}_${VERSION}*_$DPKG_ARCH.deb

lintian -I -i \
  --suppress-tags maintainer-upload-has-incorrect-version-number,changelog-should-mention-nmu,empty-debian-diff,debian-rules-uses-deprecated-makefile,testsuite-autopkgtest-missing *.dsc

exit 0
