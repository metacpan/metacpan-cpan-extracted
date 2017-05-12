#!/bin/bash

DIR=Perl-modules/html/Text/Balanced
FILE=Marpa.html

mkdir -p $DR/$DIR ~/savage.net.au/$DIR

pod2html.pl -i lib/Text/Balanced/Marpa.pm -o $DR/$DIR/$FILE

cp $DR/$DIR/$FILE ~/savage.net.au/$DIR
