#!/usr/bin/perl

use Test::More tests => 1;
require 't/auxfunctions.pl';

my $com = "perl -Mblib ./ngrams.pl --n=2 --orderby=ngram --type=word".
                 " --normalize t/05.in";
my $out = normalize(`$com`);

#putfile('t/10.out', $out);

is(normalize(scalar(getfile('t/10.out'))), $out);
