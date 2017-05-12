#!/bin/bash

DIR=Perl-modules/html/Text/Table
FILE=Manifold.html

mkdir -p $DR/$DIR ~/savage.net.au/$DIR

pod2html.pl -i lib/Text/Table/Manifold.pm -o $DR/$DIR/$FILE

cp $DR/$DIR/$FILE ~/savage.net.au/$DIR
