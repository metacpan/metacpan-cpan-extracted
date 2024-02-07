#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

use Mojo::Util::Benchmark;

my $benchmark = Mojo::Util::Benchmark->new();

my $routine = sub {
    # do something
};

my $average = $benchmark->average($routine, 10);

is($average >= 0, 1, "Average is greater than 0");
is($average <= 1, 1, "Average is smaller than 1");
is($average =~ /^\d+\.\d{12}$/, 1, "Contains 12 decimal places");

done_testing();
