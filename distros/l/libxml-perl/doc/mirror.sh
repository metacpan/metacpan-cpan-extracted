#! /bin/sh
#
# NAME
#     mirror -- update web page with a libxml-perl release
#
# SYNOPSIS
usage="mirror RELEASE DESTDIR"
#
# DESCRIPTION
#     `mirror' creates a web mirror using a libxml-perl release tar
#     file.
#
#     `mirror' pulls files from the tar file to create the web page.
#     `mirror' searches HTML files for the string @VERSION@ and
#     replaces it with RELEASE.  `mirror' searches for all *.pm and
#     *.pod files and converts them to HTML.  It also copies a few
#     hardcoded files.
#
#     `mirror' installs the web pages in DESTDIR.
#
#     CAUTION: `mirror' removes the contents of DESTDIR before
#     copying files to it.
#
# AUTHOR
#     Ken MacLeod
#
# $Id: mirror.sh,v 1.2 2000/02/22 21:02:56 kmacleod Exp $
#

PWD_CMD="/bin/pwd"
SED="sed"
TR="/usr/bin/tr"

if [ $# != 2 ]; then
  echo "usage: $usage"
  exit 1
fi

RELEASE="$1"
DESTDIR="$2"

set -e
set -x

rm -rf $DESTDIR
mkdir -p $DESTDIR

cp libxml-perl-${RELEASE}.tar.gz $DESTDIR

cd $DESTDIR

tar xzvf libxml-perl-${RELEASE}.tar.gz

for ii in libxml-perl-${RELEASE}/doc/*.html; do
  $SED <$ii >`basename $ii` \
    -e "s/@VERSION@/$RELEASE/g"
done
for ii in `cd libxml-perl-${RELEASE}/doc; echo *.pod`; do
    pod2html libxml-perl-${RELEASE}/doc/$ii >`basename $ii .pod`.html
done
for ii in `cd libxml-perl-${RELEASE}/lib; echo */*.pm */*/*.pm`; do
    dstfile=`echo $ii | sed -e 's|/|::|g'`
    pod2html libxml-perl-${RELEASE}/lib/$ii >`basename $dstfile .pm`.html
done

mv libxml-perl-${RELEASE}/README libxml-perl-${RELEASE}.readme
mv libxml-perl-${RELEASE}/doc/modules.xml .

rm -rf libxml-perl-${RELEASE} pod2html-dircache pod2html-itemcache
