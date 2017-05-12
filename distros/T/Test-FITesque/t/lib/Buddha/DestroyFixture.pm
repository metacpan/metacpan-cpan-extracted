package Buddha::DestroyFixture;

use strict;
use warnings;

use base qw(Test::FITesque::Fixture);

our $DESTROY_HAS_RUN = undef;

sub hehe {
  return 1;
}

sub DESTROY {
  $DESTROY_HAS_RUN = 1;
}

1;
