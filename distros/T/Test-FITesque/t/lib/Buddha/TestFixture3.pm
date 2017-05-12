package Buddha::TestFixture3;

use strict;
use warnings;
use base qw(Test::FITesque::Fixture);

our $NEW;
our $OBJ;
sub new {
  my ($class, $value) = @_;
  $NEW = $value;
  return bless {}, $class;
}

sub object_method {
  my ($self, $value) = @_;
  die "Not called as an object method" if !ref $self;
  $OBJ = $value;
}

sub parse_arguments {
  my ($class, @args) = @_;
  return map { uc($_) } @args;
}

1;
