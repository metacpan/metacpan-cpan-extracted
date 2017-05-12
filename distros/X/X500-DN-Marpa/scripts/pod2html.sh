#!/bin/bash

DIR1=Perl-modules/html
DIR2=X500/DN
DIRS=$DIR1/$DIR2

mkdir -p ~/savage.net.au/$DIRS/Marpa
mkdir -p $DR/$DIRS/Marpa

pod2html.pl -i lib/X500/DN/Marpa.pm         -o $DR/$DIRS/Marpa.html
pod2html.pl -i lib/X500/DN/Marpa/Actions.pm -o $DR/$DIRS/Marpa/Actions.html
pod2html.pl -i lib/X500/DN/Marpa/DN.pm      -o $DR/$DIRS/Marpa/DN.html
pod2html.pl -i lib/X500/DN/Marpa/RDN.pm     -o $DR/$DIRS/Marpa/RDN.html

cp -r $DR/$DIRS/* ~/savage.net.au/$DIRS
