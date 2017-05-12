#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Unicode::Diacritic::Strip 'strip_alphabet';
binmode STDOUT, ":encoding(utf8)";
my $stuff = '89. ročník udílení Oscarů';
my ($out, $list) = strip_alphabet ($stuff);
for my $k (keys %$list) {
    print "$k was converted to $list->{$k}\n";
}
