package Zing::Table;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

extends 'Zing::Channel';

our $VERSION = '0.25'; # VERSION

# ATTRIBUTES

has 'type' => (
  is => 'rw',
  isa => 'TableType',
  def => 'domain',
);

has 'position' => (
  is => 'rw',
  isa => 'Maybe[Int]',
  def => undef,
);

# METHODS

method count() {
  return int $self->size;
}

method drop() {
  return $self->store->drop($self->term);
}

method fetch(Int $size = 1) {
  my $results = [];

  for (1..$size) {
    if (my $domain = $self->next) {
      push @$results, $domain;
    }
  }

  return $results;
}

method first() {
  return $self->head;
}

method get(Str $key) {
  my $type = $self->type;
  return $self->app->$type(name => $key);
}

method head() {
  my $position = 0;

  if (my $data = $self->store->slot($self->term, $position)) {
    return $self->app->term($data->{term})->object;
  }
  else {
    return undef;
  }
}

method index(Int $position) {
  if (my $data = $self->store->slot($self->term, $position)) {
    return $self->app->term($data->{term})->object;
  }
  else {
    return undef;
  }
}

method last() {
  return $self->tail;
}

method next() {
  my $position = $self->position;

  if (!defined $position) {
    $position = 0;
  }
  else {
    $position++;
  }
  if (my $data = $self->store->slot($self->term, $position)) {
    $self->position($position);
    return $self->app->term($data->{term})->object;
  }
  else {
    $self->position($position) if $position == $self->size;
    return undef;
  }
}

method prev() {
  my $position = $self->position;

  if (!defined $position) {
    return undef;
  }
  elsif ($position == 0) {
    $self->position(undef);
    return undef;
  }
  else {
    $position--;
  }
  if (my $data = $self->store->slot($self->term, $position)) {
    $self->position($position);
    return $self->app->term($data->{term})->object;
  }
  else {
    return undef;
  }
}

around recv() {
  if (my $data = $self->$orig) {
    return $self->app->term($data->{term})->object;
  }
  else {
    return undef;
  }
}

method renew() {
  return $self->reset if (($self->{position} || 0) + 1) > $self->size;
  return 0;
}

method reset() {
  return !($self->{position} = undef);
}

method set(Str $key) {
  my $type = $self->type;
  my $repo = $self->app->$type(name => $key);
  $self->send({term => $repo->term});
  return $repo;
}

method tail() {
  my $size = $self->size;
  my $position = $size ? ($size - 1) : 0;

  if (my $data = $self->store->slot($self->term, $position)) {
    return $self->app->term($data->{term})->object;
  }
  else {
    return undef;
  }
}

method term() {
  return $self->app->term($self)->table;
}

1;

=encoding utf8

=head1 NAME

Zing::Table - Entity Lookup Table

=cut

=head1 ABSTRACT

Entity Lookup Table Construct

=cut

=head1 SYNOPSIS

  use Zing::Table;

  my $table = Zing::Table->new(name => 'users');

  # my $domain = $table->set('unique-id');

=cut

=head1 DESCRIPTION

This package provides an index and lookup-table for L<Zing::Repo> derived data
structures which provides the ability to create a collection of repo objects.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Zing::Channel>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Zing::Types>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 position

  position(Maybe[Int])

This attribute is read-write, accepts C<(Maybe[Int])> values, and is optional.

=cut

=head2 type

  type(TableType)

This attribute is read-only, accepts C<(TableType)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 count

  count() : Int

The count method returns the number of L<Zing::Repo> objects in the table.

=over 4

=item count example #1

  # given: synopsis

  $table->count;

=back

=over 4

=item count example #2

  # given: synopsis

  $table->set('user-12345');

  $table->count;

=back

=cut

=head2 drop

  drop() : Int

The drop method returns truthy if the table has been destroyed. This operation
does not cascade.

=over 4

=item drop example #1

  # given: synopsis

  $table->drop;

=back

=cut

=head2 fetch

  fetch(Int $size = 1) : ArrayRef[Repo]

The fetch method returns the next C<n> L<Zing::Repo> objects from the table.

=over 4

=item fetch example #1

  # given: synopsis

  $table->fetch;

=back

=over 4

=item fetch example #2

  # given: synopsis

  $table->set('user-12345');
  $table->set('user-12346');
  $table->set('user-12347');

  $table->fetch(5);

=back

=cut

=head2 first

  first() : Maybe[Repo]

The first method returns the first L<Zing::Repo> object created in the table.

=over 4

=item first example #1

  # given: synopsis

  $table->first;

=back

=cut

=head2 get

  get(Str $key) : Maybe[Repo]

The get method returns the L<Zing::Repo> associated with a specific key.

=over 4

=item get example #1

  # given: synopsis

  $table->get('user-12345');

=back

=cut

=head2 head

  head() : Maybe[Repo]

The head method returns the first L<Zing::Repo> object created in the table.

=over 4

=item head example #1

  # given: synopsis

  $table->head;

=back

=cut

=head2 index

  index(Int $position) : Maybe[Repo]

The index method returns the L<Zing::Repo> object at the position (index) specified.

=over 4

=item index example #1

  # given: synopsis

  $table->index(0);

=back

=cut

=head2 last

  last() : Maybe[Repo]

The last method returns the last L<Zing::Repo> object created in the table.

=over 4

=item last example #1

  # given: synopsis

  $table->last;

=back

=cut

=head2 next

  next() : Maybe[Repo]

The next method returns the next L<Zing::Repo> object created in the table.

=over 4

=item next example #1

  # given: synopsis

  $table->next;

=back

=over 4

=item next example #2

  # given: synopsis

  $table->position(undef);

  $table->prev;
  $table->prev;
  $table->next;

=back

=over 4

=item next example #3

  # given: synopsis

  $table->position($table->size);

  $table->prev;
  $table->next;
  $table->prev;

=back

=cut

=head2 prev

  prev() : Maybe[Repo]

The prev method returns the previous L<Zing::Repo> object created in the table.

=over 4

=item prev example #1

  # given: synopsis

  $table->prev;

=back

=over 4

=item prev example #2

  # given: synopsis

  $table->next;
  $table->next;
  $table->prev;

=back

=over 4

=item prev example #3

  # given: synopsis

  $table->position($table->size);

  $table->next;
  $table->next;
  $table->prev;

=back

=over 4

=item prev example #4

  # given: synopsis

  $table->position(undef);

  $table->next;
  $table->prev;
  $table->next;

=back

=cut

=head2 renew

  renew() : Int

The renew method returns truthy if it resets the internal cursor, otherwise falsy.

=over 4

=item renew example #1

  # given: synopsis

  $table->renew;

=back

=cut

=head2 reset

  reset() : Int

The reset method always reset the internal cursor and return truthy.

=over 4

=item reset example #1

  # given: synopsis

  $table->reset;

=back

=cut

=head2 set

  set(Str $key) : Repo

The set method creates a L<Zing::Repo> association with a specific key in the
table. The key should be unique. Adding the same key will result in duplicate
entries.

=over 4

=item set example #1

  # given: synopsis

  $table->set('user-12345');

=back

=cut

=head2 tail

  tail() : Maybe[Repo]

The tail method returns the last L<Zing::Repo> object created in the table.

=over 4

=item tail example #1

  # given: synopsis

  $table->tail;

=back

=cut

=head2 term

  term() : Str

The term method returns the name of the table.

=over 4

=item term example #1

  # given: synopsis

  $table->term;

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
