use Test::Given;
require 't/test_helper.pl';
use strict;
use warnings;

our ($lines);

describe 'Exceptions in Given' => sub {
  Given lines => sub { run_spec('t/t/exception-given.t') };
  Then sub { contains($lines, qr%Given died at t/t/.* line%) };
  And  sub { contains($lines, qr/You planned 3 tests but ran 1/) };
  And  sub { not contains($lines, qr/never reached/) };
};

describe 'Exceptions in Given And' => sub {
  Given lines => sub { run_spec('t/t/exception-given-and.t') };
  Then sub { contains($lines, qr%Given And died at t/t/.* line%) };
  And  sub { contains($lines, qr/You planned 3 tests but ran 1/) };
  And  sub { not contains($lines, qr/never reached/) };
};

describe 'Exceptions in When' => sub {
  When die_hard => sub { die 'hard' };
  Invariant sub { not has_failed(shift, qr/easy/) };
  Then sub { has_failed(shift, qr/hard/) };

  context 'Nested' => sub {
    When sub {};
    And  vengeance => sub { die 'with a vengeance' };
    Then sub { has_failed(shift, qr/vengeance/) };
    And  sub { has_failed(shift, qr/hard/) };
  };
};

sub only_second_test_failed {
  And sub { contains($lines, qr/(?<!not )ok 1/) };
  And sub { contains($lines, qr/not ok 2/) };
  And sub { contains($lines, qr/(?<!not )ok 3/) };
}

describe 'Exceptions in Invariant' => sub {
  Given lines => sub { run_spec('t/t/exception-invariant.t') };
  Then sub { contains($lines, qr/Invariant: #line/) };
  And  sub { contains($lines, qr%Invariant died at t/t/.* line%) };
  only_second_test_failed();
};

describe 'Exceptions in Invariant And' => sub {
  Given lines => sub { run_spec('t/t/exception-invariant-and.t') };
  Then sub { contains($lines, qr/Invariant: #line/) };
  And  sub { contains($lines, qr%Invariant And died at t/t/.* line%) };
  only_second_test_failed();
};

describe 'Exceptions in Then' => sub {
  Given lines => sub { run_spec('t/t/exception-then.t') };
  Then sub { contains($lines, qr/Then: #line/) };
  And  sub { contains($lines, qr%Then died at t/t/.* line%) };
  only_second_test_failed();
};

describe 'Exceptions in Then And' => sub {
  Given lines => sub { run_spec('t/t/exception-then-and.t') };
  Then sub { contains($lines, qr/And: #line/) };
  And  sub { contains($lines, qr%And died at t/t/.* line%) };
  only_second_test_failed();
};
