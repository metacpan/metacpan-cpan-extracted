use strict;
use warnings;
use Test::Script::Async;
use Test2::Bundle::Extended;

plan 4;

script_compiles 'corpus/good.pl';
script_runs(['corpus/output.pl', qw( foo bar )])
  ->note;

script_runs(['corpus/exit.pl', 22])
  ->note
  ->diag_if_fail;

SKIP: {

  skip 'do not test signals', 1 if $^O eq 'MSWin32';

  script_runs(['corpus/signal.pl', 9])
    ->note;

}
