package Fitnesse::Slim::Test::InvocationArity;

use strict;
use warnings;

our $CONSTRUCTIONS = 0;
our $CALLS = 0;

sub slim_constructor_signature { { parameters => ['Integer'] } }
sub slim_enum_types { { Color => [qw(RED GREEN BLUE)] } }

sub new {
  my ($class, $value) = @_;
  ++$CONSTRUCTIONS;
  bless {
    value => $value,
    system_under_test => bless({}, 'Fitnesse::Slim::Test::InvocationArity::Sut'),
  }, $class;
}

sub slim_method_signature {
  my ($self, $method) = @_;
  return { parameters => ['String'], return => 'String' }
    if $method eq 'typed';
  return { parameters => [], return => 'String' }
    if $method eq 'no_args';
  return { parameters => ['Color'], return => 'Color' }
    if $method eq 'color';
  return { parameters => ['List<Integer>'], return => 'String' }
    if $method eq 'sequence';
  return { return => 'String' } if $method eq 'dynamic';
  return;
}

sub typed {
  my ($self, $value) = @_;
  ++$CALLS;
  return $value;
}

sub no_args { ++$CALLS; 'zero' }
sub color { ++$CALLS; $_[1] }
sub sequence { ++$CALLS; join ',', @{$_[1]} }
sub dynamic { my ($self, @args) = @_; return join '|', @args }
sub untyped { my ($self, @args) = @_; return join '|', @args }
sub value { $_[0]{value} }

package Fitnesse::Slim::Test::InvocationArity::Sut;

use strict;
use warnings;

our $CALLS = 0;

sub slim_method_signature {
  my ($self, $method) = @_;
  return { parameters => ['Integer'], return => 'Integer' }
    if $method eq 'sut_typed';
  return { parameters => ['String', 'String'], return => 'String' }
    if $method eq 'typed';
  return;
}

sub sut_typed { ++$CALLS; $_[1] }
sub typed { ++$CALLS; 'sut' }

1;
