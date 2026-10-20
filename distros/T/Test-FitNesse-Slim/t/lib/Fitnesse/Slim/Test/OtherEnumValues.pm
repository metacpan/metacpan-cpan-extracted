package Fitnesse::Slim::Test::OtherEnumValues;

use strict;
use warnings;

sub slim_enum_types { return { Color => [qw(CYAN MAGENTA)] } }
sub slim_method_signature {
  my ($self, $method) = @_;
  return { parameters => ['Color'], return => 'Color' } if $method eq 'echo_color';
}
sub new { bless {}, $_[0] }
sub echo_color { $_[1] }

1;
