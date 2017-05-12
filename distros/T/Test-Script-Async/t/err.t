use strict;
use warnings;
use Test2::Bundle::Extended;
use Test::Script::Async;

plan 2;

my $run = script_runs "corpus/output.pl";

is $run->err, [map { "stderr $_" } qw( one two three four ) ], 'error output matches';
