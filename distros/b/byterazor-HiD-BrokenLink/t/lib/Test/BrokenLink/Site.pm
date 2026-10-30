# Minimal stand-in for a HiD site object, exposing only the interface
# that byterazor::HiD::BrokenLink uses.

package Test::BrokenLink::Site;

use Moose;

use 5.014; # strict

has config => (
  is       => 'ro' ,
  isa      => 'HashRef' ,
  required => 1 ,
);

has destination => (
  is       => 'ro' ,
  isa      => 'Str' ,
  required => 1 ,
);

has messages => (
  is      => 'rw' ,
  isa     => 'ArrayRef' ,
  default => sub { [] } ,
);

sub INFO {
  my( $self , $message ) = @_;
  push @{ $self->messages } , [ 'INFO' , $message ];
  return;
}

sub WARN {
  my( $self , $message ) = @_;
  push @{ $self->messages } , [ 'WARN' , $message ];
  return;
}

__PACKAGE__->meta->make_immutable;
1;
