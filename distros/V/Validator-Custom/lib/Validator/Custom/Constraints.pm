# Version 0 module
package Validator::Custom::Constraints;
use Object::Simple -base;

use Scalar::Util;

has 'constraints';

sub AUTOLOAD {
  my $self = shift;

  my ($package, $method) = split /::(\w+)$/, our $AUTOLOAD;
  Carp::croak "Undefined subroutine &${package}::$method called"
    unless Scalar::Util::blessed $self && $self->isa(__PACKAGE__);

  # Call helper with current controller
  Carp::croak qq{Can't locate object method "$method" via package "$package"}
    unless my $helper = $self->constraints->{$method};
  return $helper->(@_);
}

sub DESTROY { }

1;

=head1 NAME

Validator::Custom::Constraints -  Constraint autoloading system
