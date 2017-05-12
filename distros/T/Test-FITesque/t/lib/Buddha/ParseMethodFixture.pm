package Buddha::ParseMethodFixture;

use strict;
use warnings;
use base qw(Test::FITesque::Fixture);

sub one_two_three : Test {
  return 'one_two_three';
}

1;
