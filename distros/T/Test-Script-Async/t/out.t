use strict;
use warnings;
use Test2::Bundle::Extended;
use Test::Script::Async;

plan 2;

my $run = script_runs "corpus/output.pl";

is $run->out, [map { "stdout $_" } qw( one two three four ) ], 'output matches';
