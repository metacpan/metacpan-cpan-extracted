package Buddha::SuiteFixture;

use strict;
use warnings;
use base qw(Test::FITesque::Fixture);

our $RECORDED = [];
our $NOT_A_TEST_RUN = 0;

sub foo : Test {
  my ($self) = @_;
  push @$RECORDED, 'foo';
}

sub bar : Test : Plan(2) {
  my ($self) = @_;
  push @$RECORDED, 'bar';
}

sub baz : Test : Plan(3) {
  my ($self) = @_;
  push @$RECORDED, 'baz';
}

sub not_a_test {
  $NOT_A_TEST_RUN = 1;
}

1;
