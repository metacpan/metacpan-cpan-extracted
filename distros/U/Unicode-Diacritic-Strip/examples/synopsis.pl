#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use Unicode::Diacritic::Strip ':all';
my $in = 'àÀâÂäçéÉèÈêÊëîïôùÙûüÜがぎぐげご';
binmode STDOUT, ":encoding(utf8)";
print strip_diacritics ($in), "\n";
print fast_strip ($in), "\n";

