#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Unicode::Diacritic::Strip 'fast_strip';
my $unicode = 'Bjørn Łódź';
print fast_strip ($unicode), "\n";

