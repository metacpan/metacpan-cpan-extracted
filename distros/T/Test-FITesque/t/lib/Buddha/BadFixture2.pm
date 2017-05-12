package Buddha::BadFixture2;

use strict;
use warnings;
use base qw(Test::FITesque::Fixture);

sub tai : Test : Plan {
  return 'tai';
}

1;
