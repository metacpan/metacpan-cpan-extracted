package SetUpTearDownTest;

use strict;
use warnings;

use Test::Unit::Lite;
use base 'Test::Unit::TestCase';

my $a;

sub set_up {
  $a = 1;
}

sub test_inc {
  my $self = shift;
  $a++;
  $self->assert_equals(2, $a);
}

sub test_dec {
  my $self = shift;
  $a--;
  $self->assert_equals(0, $a);
}

1;
