use strict;
use warnings;
use Test2::Bundle::Extended;
use Test::Script::Async;

plan 3;

my $run = script_runs 'corpus/output.pl';

is(
  intercept { $run->diag_if_fail },
  array {
    end;
  },
  "no diagnostic",
);

intercept { $run->exit_is(22) };

is(
  intercept { $run->diag_if_fail },
  array {
    event Diag => {};
  },
  "a diagnostic",
);
