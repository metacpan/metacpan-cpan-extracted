package Buddha::BadFixture3;

use strict;
use warnings;
use base qw(Test::FITesque::Fixture);

sub tai : Test : Plan(0) {
  return 'tai';
}

1;
