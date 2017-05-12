#!/usr/bin/env perl

use warnings;
use strict;
use utf8;

BEGIN {
    use FindBin;
    use lib "$FindBin::Bin/../lib";
}
use WWW::Metalgate;
use YAML::Syck;
use XXX;

my $index   = WWW::Metalgate->review_index;
my @artists = $index->artists;
my $i = 1;
my @albums;
for my $artist (@artists) {
    warn $artist->name;
    push @albums, $artist->review->albums;
#    last if $i++ % 10 == 0;
}
DumpFile("tmp/albums", \@albums);

print "succeeded.\n";
