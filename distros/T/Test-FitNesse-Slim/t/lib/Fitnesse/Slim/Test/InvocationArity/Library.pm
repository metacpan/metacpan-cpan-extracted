package Fitnesse::Slim::Test::InvocationArity::Library;

use strict;
use warnings;

our $CALLS = 0;

sub new { bless {}, $_[0] }

sub slim_method_signature {
  my ($self, $method) = @_;
  return { parameters => ['java.lang.Double'], return => 'java.lang.Double' }
    if $method eq 'library_typed';
  return { parameters => ['String', 'String'], return => 'String' }
    if $method eq 'typed';
  return;
}

sub library_typed { ++$CALLS; $_[1] }
sub typed { ++$CALLS; 'library' }

1;
