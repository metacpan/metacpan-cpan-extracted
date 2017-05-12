package Buddha::SuiteRunTest;

use strict;
use warnings;
use base qw(Test::FITesque::Fixture);
use Test::More;

sub foo : Test {
  ok 0, q{foo fails};
}

sub bar : Test : Plan(2) {
  ok 1, q{bar: first};
  ok 1, q{bar: second};
}

sub baz : Test : Plan(3) {
  ok 1, q{baz: first};
  ok 1, q{baz: second};
  ok 1, q{baz: third};
}

1;
