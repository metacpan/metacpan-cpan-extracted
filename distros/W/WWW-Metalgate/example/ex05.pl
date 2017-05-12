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

my @years = WWW::Metalgate->years;
my @tunes = map { $_->best_tunes } @years;
DumpFile("tmp/tunes", \@tunes);

print "succeeded.\n";
