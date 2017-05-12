use Test::Given;
require 't/test_helper.pl';
use strict;
use warnings;

our ($lines);

describe 'Failing Then' => sub {
  Given lines => sub { run_spec('t/t/failing-then.t') };
  Then sub { contains($lines, qr/Then: #line/) };
  And  sub { contains($lines, qr/not ok 1 - undef/) };
};

describe 'Failing And' => sub {
  Given lines => sub { run_spec('t/t/failing-and.t') };
  Then sub { contains($lines, qr/And: #line/) };
  And  sub { contains($lines, qr/not ok 1 - 'Passing Then'/) };
};

describe 'Failing Invariant in current context' => sub {
  Given lines => sub { run_spec('t/t/failing-invariant-current.t') };
  Then sub { contains($lines, qr/Invariant: #line/) };
  And  sub { contains($lines, qr/not ok 1 - 'Passing Then'/) };
};

describe 'Failing Invariant in ancestor context' => sub {
  Given lines => sub { run_spec('t/t/failing-invariant-ancestor.t') };
  Then sub { contains($lines, qr/Invariant: #line/) };
  And  sub { contains($lines, qr/not ok 1 - 'Outer passing Then'/) };
  And  sub { contains($lines, qr/not ok 2 - 'Inner passing Then'/) };
};
