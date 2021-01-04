package Zing::Cursor;

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

has 'position' => (
  is => 'rw',
  isa => 'Maybe[Str]',
  opt => 1,
);

has 'lookup' => (
  is => 'ro',
  isa => 'Lookup',
  req => 1,
);

# METHODS

method count() {
  return int keys %{$self->lookup->state};
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
  my $tail = $self->lookup->tail or return undef;

  my $reference = $self->lookup->state->{$tail} or return undef;

  return $self->app->domain(name => $reference->{name});

}

method last() {
  my $head = $self->lookup->head or return undef;

  my $reference = $self->lookup->state->{$head} or return undef;

  return $self->app->domain(name => $reference->{name});
}

method next() {
  my $position = $self->position;

  if ($self->{prev_null} || (!$position && !$self->{initial})) {
    if (!$position) {
      $position = $self->lookup->tail;
    }

    if ($self->{initial}) {
      $self->{initial} ||= $position;
    }

    delete $self->{prev_null};

    if (!$position) {
      return undef;
    }

    my $current = $self->lookup->state->{$position} or return undef;

    $self->position($position);

    return $self->app->domain(name => $current->{name});
  }

  if (!$position) {
    return undef;
  }

  my $current = $self->lookup->state->{$position} or return undef;

  if (!$current->{next}) {
    $self->{next_null} = 1;

    return undef;
  }

  $self->position($current->{next});

  my $endpoint = $self->lookup->state->{$current->{next}} or return undef;

  return $self->app->domain(name => $endpoint->{name});
}

method prev() {
  my $position = $self->position;

  if ($self->{next_null} || (!$position && !$self->{initial})) {
    if (!$position) {
      $position = $self->lookup->head;
    }

    if ($self->{initial}) {
      $self->{initial} ||= $position;
    }

    delete $self->{next_null};

    if (!$position) {
      return undef;
    }

    my $current = $self->lookup->state->{$position} or return undef;

    $self->position($position);

    return $self->app->domain(name => $current->{name});
  }

  if (!$position) {
    return undef;
  }

  my $current = $self->lookup->state->{$position} or return undef;

  if (!$current->{prev}) {
    $self->{prev_null} = 1;

    return undef;
  }

  $self->position($current->{prev});

  my $endpoint = $self->lookup->state->{$current->{prev}} or return undef;

  return $self->app->domain(name => $endpoint->{name});
}

method reset() {
  $self->position($self->{initial}) if !$self->{initial};

  return $self;
}

1;

=encoding utf8

=head1 NAME

Zing::Cursor - Lookup Table Traversal

=cut

=head1 ABSTRACT

Lookup Table Traversal Construct

=cut

=head1 SYNOPSIS

  use Zing::Lookup;
  use Zing::Cursor;

  my $lookup = Zing::Lookup->new(name => 'users');

  $lookup->set('user-12345')->set(username => 'u12345');
  $lookup->set('user-12346')->set(username => 'u12346');
  $lookup->set('user-12347')->set(username => 'u12347');

  my $cursor = Zing::Cursor->new(lookup => $lookup);

  # $cursor->count;

=cut

=head1 DESCRIPTION

This package provides a cursor for traversing L<Zing::Lookup> indices and
supports forward and backwards traversal as well as token-based pagination.

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

=head2 position

  position(Maybe[Str])

This attribute is read-write, accepts C<(Maybe[Str])> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 count

  count() : Int

The count method returns the number of L<Zing::Domain> objects in the lookup
table.

=over 4

=item count example #1

  # given: synopsis

  $cursor->count;

=back

=cut

=head2 fetch

  fetch(Int $size = 1) : ArrayRef[Domain]

The fetch method returns the next C<n> L<Zing::Domain> objects from the lookup
table.

=over 4

=item fetch example #1

  # given: synopsis

  $cursor->fetch;

=back

=over 4

=item fetch example #2

  # given: synopsis

  $cursor->fetch(5);

=back

=cut

=head2 first

  first() : Maybe[Domain]

The first method returns the first L<Zing::Domain> object created in the lookup
table.

=over 4

=item first example #1

  # given: synopsis

  $cursor->first;

=back

=cut

=head2 last

  last() : Maybe[Domain]

The last method returns the last L<Zing::Domain> object created in the lookup
table.

=over 4

=item last example #1

  # given: synopsis

  $cursor->last;

=back

=cut

=head2 next

  next() : Maybe[Domain]

The next method returns the next (after the current position) L<Zing::Domain>
object in the lookup table.

=over 4

=item next example #1

  # given: synopsis

  $cursor->next;

=back

=over 4

=item next example #2

  # given: synopsis

  $cursor->next;
  $cursor->next;

=back

=cut

=head2 prev

  prev() : Maybe[Domain]

The prev method returns the prev (before the current position) L<Zing::Domain>
object in the lookup table.

=over 4

=item prev example #1

  # given: synopsis

  $cursor->prev;

=back

=over 4

=item prev example #2

  # given: synopsis

  $cursor->prev;
  $cursor->prev;

=back

=cut

=head2 reset

  reset() : Cursor

The reset method returns the cursor to its starting position (defined at
construction).

=over 4

=item reset example #1

  # given: synopsis

  $cursor->prev;
  $cursor->next;
  $cursor->next;

  $cursor->reset;

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
