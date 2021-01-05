package Zing::Lookup;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

extends 'Zing::Domain';

our $VERSION = '0.26'; # VERSION

# BUILDERS

fun BUILD($self) {
  my $savepoint = $self->savepoint;

  if ($savepoint->test) {
    $self->{state} = $savepoint->snapshot;
    $self->{position} = $savepoint->position;
    $self->{metadata} = $savepoint->metadata;
  }

  return $self->apply;
}

# METHODS

method cursor() {
  return $self->app->cursor(lookup => $self);
}

method decr(Any @args) {
  $self->throw(error_not_supported($self, 'decr'));
}

around del($key) {
  my $name = $self->hash($key);
  my $item = $self->state->{$name};
  return $self if !$item;
  my $next = $item->{next};
  my $prev = $item->{prev};
  if ($next && $prev) {
    $self->change('set', $prev, {%{$self->state->{$prev}}, next => $next});
    $self->change('set', $next, {%{$self->state->{$next}}, prev => $prev});
  }
  elsif ($next && !$prev) {
    $self->metadata->{tail} = $next;
    $self->change('set', $next, {%{$self->state->{$next}}, prev => undef});
  }
  elsif (!$next && $prev) {
    $self->metadata->{head} = $prev;
    $self->change('set', $prev, {%{$self->state->{$prev}}, next => undef});
  }
  $self->$orig($name);
  $self->app->domain(name => $item->{name})->drop;
  return $self;
}

around drop() {
  if (my $savepoint = $self->savepoint) {
    $savepoint->drop if $savepoint->test;
  }
  return $self->$orig;
}

method get(Str $key) {
  my $data = $self->apply->state->{$self->hash($key)};
  return undef if !$data;
  return $self->app->domain(name => $data->{name});
}

method head() {
  return $self->metadata->{head};
}

method incr(Any @args) {
  $self->throw(error_not_supported($self, 'incr'));
}

method hash(Str $key) {
  require Digest::SHA; Digest::SHA::sha1_hex($key);
}

method pop(Any @args) {
  $self->throw(error_not_supported($self, 'pop'));
}

method push(Any @args) {
  $self->throw(error_not_supported($self, 'push'));
}

method restore(HashRef $data) {
  return $self->{state} = {};
}

method set(Str $key) {
  my $hash = $self->hash($key);
  my $name = $key;
  my $domain = $self->app->domain(name => $name);
  my $prev = $self->apply->head;
  if ($prev && $self->state->{$prev}) {
    $self->change('set', $prev, {%{$self->state->{$prev}}, next => $hash});
  }
  $self->metadata->{head} = $hash;
  $self->metadata->{tail} = $hash if !$self->metadata->{tail};
  $self->change('set', $hash, {name => $name, next => undef, prev => $prev});
  return $domain;
}

method shift(Any @args) {
  $self->throw(error_not_supported($self, 'shift'));
}

method savepoint() {
  return $self->app->savepoint(lookup => $self);
}

method snapshot() {
  return {};
}

method tail() {
  return $self->metadata->{tail};
}

method term() {
  return $self->app->term($self)->lookup;
}

method unshift(Any @args) {
  $self->throw(error_not_supported($self, 'unshift'));
}

# ERRORS

fun error_not_supported(Object $object, Str $method) {
  code => 'error_not_implemented',
  message => "@{[ref($object)]} method \"$method\" not supported",
}

1;

=encoding utf8

=head1 NAME

Zing::Lookup - Domain Lookup Table

=cut

=head1 ABSTRACT

Domain Lookup Table Construct

=cut

=head1 SYNOPSIS

  use Zing::Lookup;

  my $lookup = Zing::Lookup->new(name => 'users');

  # my $domain = $lookup->set('unique-id');

=cut

=head1 DESCRIPTION

This package provides an index and lookup-table for L<Zing::Domain> data
structures which provides the ability to create a collection of domains with
full history of state changes.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Zing::Domain>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Zing::Types>

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 cursor

  cursor() : Cursor

The cursor method returns a L<Zing::Cursor> object which provides the ability
to page-through and traverse the lookup dataset forwards and backwards.

=over 4

=item cursor example #1

  # given: synopsis

  $lookup->cursor;

=back

=cut

=head2 del

  del(Str $key) : Lookup

The del method deletes the L<Zing::Domain> associated with a specific key.

=over 4

=item del example #1

  # given: synopsis

  $lookup->del('user-12345');

=back

=over 4

=item del example #2

  # given: synopsis

  $lookup->set('user-12345', 'me@example.com');

  $lookup->del('user-12345');

=back

=cut

=head2 drop

  drop() : Int

The drop method returns truthy if the lookup has been destroyed. This operation
does not cascade.

=over 4

=item drop example #1

  # given: synopsis

  $lookup->set('user-12345', 'me@example.com');

  $lookup->drop;

=back

=over 4

=item drop example #2

  # given: synopsis

  $lookup->set('user-12345', 'me@example.com');

  $lookup->savepoint->send;

  $lookup->drop;

=back

=cut

=head2 get

  get(Str $key) : Maybe[Domain]

The get method return the L<Zing::Domain> associated with a specific key.

=over 4

=item get example #1

  # given: synopsis

  $lookup->get('user-12345');

=back

=over 4

=item get example #2

  # given: synopsis

  $lookup->set('user-12345')->set(email => 'me@example.com');

  $lookup->get('user-12345');

=back

=cut

=head2 savepoint

  savepoint() : Savepoint

The savepoint method returns a L<Zing::Savepoint> object which provides the
ability to save and restore large indices (lookup states). If a lookup has an
associated savepoint it will be loaded automatically on object construction.

=over 4

=item savepoint example #1

  # given: synopsis

  $lookup->savepoint;

=back

=cut

=head2 set

  set(Str $key) : Domain

The set method creates a L<Zing::Domain> association with a specific key in the
lookup. The key must be unique or will overwrite any existing data.

=over 4

=item set example #1

  # given: synopsis

  $lookup->del('user-12345');

  $lookup->set('user-12345');

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
