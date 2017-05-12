use strict;
use warnings;
use Test2::Bundle::Extended;
use Test::Script::Async;

plan 5;

is script_runs("corpus/exit.pl")->exit, 0, 'exit = 0';
is script_runs(["corpus/exit.pl",22])->exit, 22, 'exit = 22';

my $run;
intercept { $run = script_runs("corpus/bogus.pl") };
is $run->exit, undef, 'exit = undef (no such script)';
