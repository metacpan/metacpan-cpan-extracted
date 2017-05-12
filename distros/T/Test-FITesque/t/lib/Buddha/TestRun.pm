package Buddha::TestRun;

use strict;
use warnings;
use base qw(Test::FITesque::Fixture);
use Test::More;

our $THINGS;

sub foo : Test {
  my ($self) = @_;
  ok 1, q{foo ran just fine};
}

sub click_me : Test : Plan(2) {
  my ($self) = @_;
  ok 1, q{click_me: first};
  ok 1, q{click_me: second};
}

sub fail_this : Test {
  my ($self) = @_;
  ok 0, q{fail_this};
}

1;
