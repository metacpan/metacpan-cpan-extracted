#!/usr/bin/env perl

use warnings;
use strict;
use utf8;

BEGIN {
    use FindBin;
    use lib "$FindBin::Bin/../lib";
}
use WWW::Metalgate;

my @years  = WWW::Metalgate->years;
my $year   = $years[0];
my @albums = $year->best_albums;

printf("--- The Best %s Albums of %s ---\n", 0+@albums, $year->year);
for my $album (@albums) {
    printf("No.%2i: %s / %s\n", $album->{no}, $album->{album}, $album->{artist});
}
