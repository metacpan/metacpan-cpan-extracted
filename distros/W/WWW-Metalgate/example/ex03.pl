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
$YAML::Syck::ImplicitUnicode=1;
use XXX;

my @albums = @{ LoadFile("tmp/albums") };
@albums = sort { $b->{point} <=> $a->{point} } @albums;
DumpFile("tmp/albums_sorted_by_point", \@albums);

print "succeeded.\n";
