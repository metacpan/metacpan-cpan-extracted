#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

use Mojo::Util::Benchmark qw(benchmark);

my $benchmark = benchmark();

isa_ok($benchmark, 'Mojo::Util::Benchmark');

done_testing();
