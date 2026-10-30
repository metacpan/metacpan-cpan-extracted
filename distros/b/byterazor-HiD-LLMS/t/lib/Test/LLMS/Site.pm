# Minimal stand-in for a HiD site object, exposing only the interface
# that byterazor::HiD::LLMS uses.

package Test::LLMS::Site;

use Moose;

use 5.014; # strict, unicode_strings

has config      => (
  is       => 'ro' ,
  isa      => 'HashRef' ,
  required => 1 ,
);

has destination => (
  is       => 'ro' ,
  isa      => 'Str' ,
  required => 1 ,
);

has pages => (
  is      => 'ro' ,
  isa     => 'ArrayRef' ,
  default => sub { [] } ,
);

has posts => (
  is      => 'ro' ,
  isa     => 'ArrayRef' ,
  default => sub { [] } ,
);

has inputs  => (
  is      => 'rw' ,
  isa     => 'HashRef' ,
  default => sub {{}} ,
);

has objects  => (
  is      => 'rw' ,
  isa     => 'ArrayRef' ,
  default => sub { [] } ,
);

has messages => (
  is      => 'rw' ,
  isa     => 'ArrayRef' ,
  default => sub { [] } ,
);

sub add_input  {
  my( $self , $key , $type ) = @_;
  $self->inputs->{$key} = $type;
  return 1;
}

sub add_object {
  my( $self , $object ) = @_;
  push @{ $self->objects } , $object;
  return 1;
}

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
