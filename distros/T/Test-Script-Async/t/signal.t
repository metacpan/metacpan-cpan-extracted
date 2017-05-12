use strict;
use warnings;
use Test2::Bundle::Extended;
use Test::Script::Async;

skip_all 'does not make sense on windows' if $^O eq 'MSWin32';
plan 2;

is script_runs(["corpus/signal.pl", 9])->signal, 9, 'signal = 9';
