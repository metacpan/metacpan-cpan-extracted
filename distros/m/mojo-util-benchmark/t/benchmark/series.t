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

my @series = $benchmark->series($routine, 5);

is(@series, 5, "Code executed 5 times");
is($series[0] >=0 , 1, "First execution time is positive number");

done_testing();
