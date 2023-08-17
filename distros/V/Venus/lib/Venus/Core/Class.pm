package Venus::Core::Class;

use 5.018;

use strict;
use warnings;

no warnings 'once';

use base 'Venus::Core';

# METHODS

sub BUILD {
  my ($self, @data) = @_;

  no strict 'refs';

  my @roles = @{$self->META->roles};

  for my $action (grep defined, map *{"${_}::BUILD"}{"CODE"}, @roles) {
    $self->$action(@data);
  }

  return $self;
}

sub DESTROY {
  my ($self, @data) = @_;

  no strict 'refs';

  my @mixins = @{$self->META->mixins};

  for my $action (grep defined, map *{"${_}::DESTROY"}{"CODE"}, @mixins) {
    $self->$action(@data);
  }

  my @roles = @{$self->META->roles};

  for my $action (grep defined, map *{"${_}::DESTROY"}{"CODE"}, @roles) {
    $self->$action(@data);
  }

  return $self;
}

sub does {
  my ($self, @args) = @_;

  return $self->DOES(@args);
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

sub import {
  my ($self, @args) = @_;

  my $target = caller;

  $self->USE($target);

  return $self->IMPORT($target, @args);
}

sub meta {
  my ($self) = @_;

  return $self->META;
}

sub new {
  my ($self, @args) = @_;

  return $self->BLESS(@args);
}

sub unimport {
  my ($self, @args) = @_;

  my $target = caller;

  return $self->UNIMPORT($target, @args);
}

1;



=head1 NAME

Venus::Core::Class - Class Base Class

=cut

=head1 ABSTRACT

Class Base Class for Perl 5

=cut

=head1 SYNOPSIS

  package User;

  use base 'Venus::Core::Class';

  package main;

  my $user = User->new(
    fname => 'Elliot',
    lname => 'Alderson',
  );

  # bless({fname => 'Elliot', lname => 'Alderson'}, 'User')

=cut

=head1 DESCRIPTION

This package provides a class base class with class building and object
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

I<Since C<1.00>>

=over 4

=item does example 1

  # given: synopsis

  my $does = $user->does('Identity');

  # 0

=back

=cut

=head2 import

  import(Any @args) (Any)

The import method invokes the C<IMPORT> lifecycle hook and is invoked whenever
the L<perlfunc/use> declaration is used.

I<Since C<2.91>>

=over 4

=item import example 1

  package main;

  use User;

  # ()

=back

=cut

=head2 meta

  meta() (Meta)

The meta method returns a L<Venus::Meta> objects which describes the package's
configuration.

I<Since C<1.00>>

=over 4

=item meta example 1

  package main;

  my $user = User->new(
    fname => 'Elliot',
    lname => 'Alderson',
  );

  my $meta = $user->meta;

  # bless({...}, 'Venus::Meta')

=back

=cut

=head2 new

  new(Any %args | HashRef $args) (Object)

The new method instantiates the class and returns a new object.

I<Since C<1.00>>

=over 4

=item new example 1

  package main;

  my $user = User->new(
    fname => 'Elliot',
    lname => 'Alderson',
  );

  # bless({fname => 'Elliot', lname => 'Alderson'}, 'User')

=back

=over 4

=item new example 2

  package main;

  my $user = User->new({
    fname => 'Elliot',
    lname => 'Alderson',
  });

  # bless({fname => 'Elliot', lname => 'Alderson'}, 'User')

=back

=cut

=head2 unimport

  unimport(Any @args) (Any)

The unimport method invokes the C<UNIMPORT> lifecycle hook and is invoked
whenever the L<perlfunc/no> declaration is used.

I<Since C<2.91>>

=over 4

=item unimport example 1

  package main;

  no User;

  # ()

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