# WWW::Auth::Base
#
# Copyright (c) 2002 Jonathan A. Waxman <jowaxman@law.upenn.edu>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.


package WWW::Auth::Base;


use strict;


sub new {
  my $proto  = shift;
  my %params = @_;

  my $class = ref ($proto) || $proto;
  my $self = {};
  bless ($self, $class);

  return $self->_init (%params) ? $self : $proto->error ($self->error);
}

sub _init {
  my $self   = shift;
  my %params = @_;

  return 1;
}

sub error {
  my $self  = shift;
  my $error = shift;

  # If an error given, set it in the object or package.
  # Otherwise, return the error from the object or package.
  if (defined $error) {
    ref ($self) ? $self->{_error} = $error : $self::_error = $error;
    return undef;
  } else {
    return ref ($self) ? $self->{_error} : $self::_error;
  }
}


1;
