package Buddha::GoodFixture;

use strict;
use warnings;
use base qw(Test::FITesque::Fixture);

sub karma : Test {
  return 'karma';
}

sub zen : Test : Plan(3) {
  return 'zen';
}

sub dharma {
  return 'dharma';
}

1;
