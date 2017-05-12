use strict;
use warnings;

use Test::More tests=>1;

my $count_of_updates = 0;

open BLT, "bin/blt -cPSF|" or die "Can't open blt: $!";
while (<BLT>) {
    $count_of_updates++ if /^<\S+>/;
    chomp;
    diag($_);
}

close BLT or die "Can't close blt: $!";

is($count_of_updates, 20);

