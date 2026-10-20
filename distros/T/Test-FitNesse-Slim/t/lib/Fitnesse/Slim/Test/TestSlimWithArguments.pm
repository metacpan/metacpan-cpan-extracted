package Fitnesse::Slim::Test::TestSlimWithArguments;

use strict;
use warnings;

sub new {
  my($class,$arg) = @_;
  bless { ARG => $arg } => $class;
}

sub arg {
  my($self) = @_;
  $self->{ARG};
}

sub set_arg {
  my($self,$arg) = @_;
  $self->{ARG} = $arg;
  "OK";
}

sub name {
  my($self) = @_;
  $self->arg->{name};
}

sub addr {
  my($self) = @_;
  $self->arg->{addr};
}

1;
