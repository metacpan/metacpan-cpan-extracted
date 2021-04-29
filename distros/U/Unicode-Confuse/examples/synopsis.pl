#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use Unicode::Confuse ':all';
binmode STDOUT, ":encoding(utf8)";
if (confusable ('ρ')) {
    my $canonical = canonical ('ρ');
    print "'ρ' is confusable with $canonical.\n";
    my @similar = similar ($canonical);
    print "$canonical is also confusable with @similar.\n";
}

