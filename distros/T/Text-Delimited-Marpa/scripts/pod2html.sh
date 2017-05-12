#!/bin/bash

DIR=Perl-modules/html/Text/Delimited
FILE=Marpa.html

mkdir -p $DR/$DIR ~/savage.net.au/$DIR

pod2html.pl -i lib/Text/Delimited/Marpa.pm -o $DR/$DIR/$FILE

cp $DR/$DIR/$FILE ~/savage.net.au/$DIR
