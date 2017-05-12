#!/usr/bin/perl

use Test::More tests => 1;
require 't/auxfunctions.pl';

my $com = "perl -Mblib ./ngrams.pl --n=10 --orderby=frequency --type=byte".
                 " --normalize --onlyfirst=100 t/11.in";
my $out = scalar(`$com`);

#putfile('t/11.out-new', $out);

is(normalize(scalar(getfile('t/11.out'))),
   normalize($out));
