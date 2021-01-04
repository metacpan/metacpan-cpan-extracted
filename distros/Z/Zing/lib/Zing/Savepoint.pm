package Zing::Savepoint;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

extends 'Zing::Entity';

our $VERSION = '0.25'; # VERSION

# ATTRIBUTES

has 'lookup' => (
  is => 'ro',
  isa => 'Lookup',
  req => 1,
);

# METHODS

method cached() {
  return $self->{cached} ||= $self->recv;
}

method capture() {
  my $properties = {};

  my $lookup = $self->lookup->apply;

  $properties->{position} = $lookup->{position};
  $properties->{metadata} = $lookup->metadata;
  $properties->{snapshot} = $lookup->state;

  return $properties;
}

method drop() {
  return $self->repo->drop;
}

method position() {
  my $capture = $self->cached or return undef;
  return $capture->{position};
}

method metadata() {
  my $capture = $self->cached or return undef;
  return $capture->{metadata};
}

method name() {
  return join('#', $self->lookup->name, 'savepoint');
}

method repo() {
  return $self->app->keyval(name => $self->name);
}

method recv() {
  return $self->repo->recv;
}

method send() {
  my $capture = $self->capture;
  $self->repo->send($capture);
  return $self->{cached} = $capture;
}

method snapshot() {
  my $capture = $self->cached or return undef;
  return $capture->{snapshot};
}

method test() {
  return $self->repo->test;
}

1;

=encoding utf8

=head1 NAME

Zing::Savepoint - Lookup Table Savepoint

=cut

=head1 ABSTRACT

Lookup Table Savepoint Construct

=cut

=head1 SYNOPSIS

  use Zing::Lookup;
  use Zing::Savepoint;

  my $lookup = Zing::Lookup->new(name => 'users');

  $lookup->set('user-12345')->set(username => 'u12345');
  $lookup->set('user-12346')->set(username => 'u12346');
  $lookup->set('user-12347')->set(username => 'u12347');

  my $savepoint = Zing::Savepoint->new(lookup => $lookup);

  # $savepoint->test;

=cut

=head1 DESCRIPTION

This package provides a savepoint mechanism for saving and restoring large
L<Zing::Lookup> indices. If a lookup has an associated savepoint it will be
used to build the index on (L<Zing::Lookup>) object construction automatically,
however, creating the savepoint (saving the state of the index) needs to be
done manually.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Zing::Types>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 lookup

  lookup(Lookup)

This attribute is read-only, accepts C<(Lookup)> values, and is required.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 capture

  capture() : HashRef

The capture method returns the relevant state properties from the lookup.

=over 4

=item capture example #1

  # given: synopsis

  $savepoint->capture;

=back

=cut

=head2 drop

  drop() : Bool

The drop method removes the persisted savepoint.

=over 4

=item drop example #1

  # given: synopsis

  $savepoint->drop;

=back

=cut

=head2 metadata

  metadata() : HashRef

The metadata method returns the cached metadata property for the lookup.

=over 4

=item metadata example #1

  # given: synopsis

  $savepoint->metadata;

=back

=cut

=head2 name

  name() : Str

The name method returns the generated savepoint name.

=over 4

=item name example #1

  # given: synopsis

  $savepoint->name;

=back

=cut

=head2 position

  position() : Int

The position method returns the cached position property for the lookup.

=over 4

=item position example #1

  use Zing::Lookup;
  use Zing::Savepoint;

  my $lookup = Zing::Lookup->new(name => 'users');
  my $savepoint = Zing::Savepoint->new(lookup => $lookup);

  $lookup->drop;
  $savepoint->drop;

  $lookup->set('user-12345')->set(username => 'u12345');
  $lookup->set('user-12346')->set(username => 'u12346');
  $lookup->set('user-12347')->set(username => 'u12347');

  $savepoint->send;
  $savepoint->position;

=back

=cut

=head2 recv

  recv() : Any

The recv method returns the data (if any) associated with the savepoint.

=over 4

=item recv example #1

  # given: synopsis

  $savepoint->recv;

=back

=cut

=head2 repo

  repo() : KeyVal

The repo method returns the L<Zing::KeyVal> object used to manage the
savepoint.

=over 4

=item repo example #1

  # given: synopsis

  $savepoint->repo;

=back

=cut

=head2 send

  send() : HashRef

The send method caches and stores the data from L</capture> as a savepoint and
returns the data.

=over 4

=item send example #1

  # given: synopsis

  $savepoint->send;

=back

=cut

=head2 snapshot

  snapshot() : HashRef

The snapshot method returns the cached snapshot property for the lookup.

=over 4

=item snapshot example #1

  # given: synopsis

  $savepoint->snapshot;

=back

=cut

=head2 test

  test() : Bool

The test method checks whether the savepoint exists and returns truthy or falsy.

=over 4

=item test example #1

  # given: synopsis

  $savepoint->repo->drop('state');

  $savepoint->test;

=back

=over 4

=item test example #2

  # given: synopsis

  $savepoint->send;

  $savepoint->test;

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
