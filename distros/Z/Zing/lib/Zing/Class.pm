package Zing::Class;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Class;

our $VERSION = '0.21'; # VERSION

# METHODS

method throw(@args) {
  require Zing::Error;
  die Zing::Error->new(@args, context => $self)->trace(1);
}

method try($method, @args) {
  require Data::Object::Try;
  my $try = Data::Object::Try->new(invocant => $self, arguments => [@args]);
  return $try->call($try->callback($self->can($method)));
}

1;

=encoding utf8

=head1 NAME

Zing::Class - Base Class

=cut

=head1 ABSTRACT

Abstract Base Class

=cut

=head1 SYNOPSIS

  use Zing::Class;

  my $class = Zing::Class->new;

  # $class->throw;

=cut

=head1 DESCRIPTION

This package provides an abstract base class for L<Zing> classes.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Zing::Types>

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 throw

  throw(Any @args) : Error

The throw method throws a L<Zing::Error> exception.

=over 4

=item throw example #1

  # given: synopsis

  $class->throw(message => 'Oops');

=back

=cut

=head2 try

  try(Str $method, Any @args) : InstanceOf["Data::Object::Try"]

The try method returns a tryable object based on the method and arguments
provided.

=over 4

=item try example #1

  # given: synopsis

  $class->try('throw', message => 'Oops');

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/zing/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/zing/wiki>

L<Project|https://github.com/iamalnewkirk/zing>

L<Initiatives|https://github.com/iamalnewkirk/zing/projects>

L<Milestones|https://github.com/iamalnewkirk/zing/milestones>

L<Contributing|https://github.com/iamalnewkirk/zing/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/zing/issues>

=cut
