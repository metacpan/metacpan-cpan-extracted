use Test::Given;
require 't/test_helper.pl';
use strict;
use warnings;

our ($lines);

describe 'Contexts without thens' => sub {
  Given lines => sub { run_spec('t/t/omitted-then.t') };
  Invariant sub { contains($lines, qr/All tests successful/) };

  context 'with no Thens' => sub {
    Then sub { contains($lines, qr/No 'Then' or 'Invariant' clauses in context: Then-less/) };
  };

  context 'with implied Then' => sub {
    Then sub { contains($lines, qr/^ok 2 - $/) };
  };
};
