package Fitnesse::Fixtures::ResponseContext;

use strict;
use warnings;

our $LAST_RESPONSE;

sub store {
  my($class,$response) = @_;
  $LAST_RESPONSE = $response;
}

sub current {
  $LAST_RESPONSE;
}

1;
