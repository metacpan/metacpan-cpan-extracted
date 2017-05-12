#!/bin/bash
#
# $DR is my web server's doc root within Debian's RAM disk :-).
# The latter is at /run/shm, so $DR is /run/shm/html.

DIR=Perl-modules/html/Tree/Cladogram

mkdir -p $DR/$DIR

pod2html.pl -i lib/Tree/Cladogram.pm             -o $DR/$DIR.html
pod2html.pl -i lib/Tree/Cladogram/Imager.pm      -o $DR/$DIR/Imager.html
pod2html.pl -i lib/Tree/Cladogram/ImageMagick.pm -o $DR/$DIR/ImageMagick.html

cp -r $DR/$DIR ~/savage.net.au/$DIR
