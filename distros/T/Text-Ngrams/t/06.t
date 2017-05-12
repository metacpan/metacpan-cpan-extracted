#!/usr/bin/perl

use Test::More tests => 1;
require 't/auxfunctions.pl';

my $out = `$^X -Mblib ./ngrams.pl --n=2 --orderby=ngram --type=word t/05.in`;

is(normalize(scalar(getfile('t/03.out'))),
   normalize($out));
