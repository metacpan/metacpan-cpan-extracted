#!perl

use strict;
use warnings;

use Benchmark qw<cmpthese>;

my $n = 10_000;

cmpthese 10, {
 'Test::More'   => sub { system "$^X -e 'use Test::More; plan q[no_plan]; pass for 1 .. $n' > /dev/null" },
 'Test::Leaner' => sub { system "$^X -e 'use lib q[lib]; use Test::Leaner; plan q[no_plan]; pass for 1 .. $n' > /dev/null" },
};
