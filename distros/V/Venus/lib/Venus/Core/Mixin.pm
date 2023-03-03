package Venus::Core::Mixin;

use 5.018;

use strict;
use warnings;

use base 'Venus::Core';

# METHODS

sub BUILD {
  my ($self) = @_;

  return $self;
}

sub DESTROY {
  my ($self) = @_;

  return;
}

sub EXPORT {
  my ($self, $into) = @_;

  return [];
}

sub IMPORT {
  my ($self, $into) = @_;

  no strict 'refs';
  no warnings 'redefine';

  for my $name (@{$self->EXPORT($into)}) {
    *{"${into}::${name}"} = \&{"@{[$self->NAME]}::${name}"};
  }

  return $self;
}

sub does {
  my ($self, @args) = @_;

  return $self->DOES(@args);
}

sub meta {
  my ($self) = @_;

  return $self->META;
}

1;



=head1 NAME

Venus::Core::Mixin - Mixin Base Class

=cut

=head1 ABSTRACT

Mixin Base Class for Perl 5

=cut

=head1 SYNOPSIS

  package Person;

  use base 'Venus::Core::Mixin';

  package User;

  use base 'Venus::Core::Class';

  package main;

  my $user = User->MIXIN('Person')->new(
    fname => 'Elliot',
    lname => 'Alderson',
  );

  # bless({fname => 'Elliot', lname => 'Alderson'}, 'User')

=cut

=head1 DESCRIPTION

This package provides a mixin base class with mixin building and object
construction lifecycle hooks.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Venus::Core>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 does

  does(Str $name) (Bool)

The does method returns true if the object is composed of the role provided.

I<Since C<1.02>>

=over 4

=item does example 1

  package Employee;

  use base 'Venus::Core::Role';

  Employee->MIXIN('Person');

  package main;

  my $user = User->ROLE('Employee')->new(
    fname => 'Elliot',
    lname => 'Alderson',
  );

  my $does = $user->does('Employee');

  # 1

=back

=cut

=head2 meta

  meta() (Meta)

The meta method returns a L<Venus::Meta> objects which describes the package's
configuration.

I<Since C<1.02>>

=over 4

=item meta example 1

  package main;

  my $user = User->ROLE('Person')->new(
    fname => 'Elliot',
    lname => 'Alderson',
  );

  my $meta = Person->meta;

  # bless({...}, 'Venus::Meta')

=back

=cut

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2000, Al Newkirk.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache license version 2.0.

=cut