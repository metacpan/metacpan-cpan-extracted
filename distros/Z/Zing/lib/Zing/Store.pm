package Zing::Store;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

extends 'Zing::Entity';

our $VERSION = '0.26'; # VERSION

# ATTRIBUTES

has 'encoder' => (
  is => 'ro',
  isa => 'Encoder',
  new => 1,
);

fun new_encoder($self) {
  $self->app->encoder
}

# METHODS

sub args {
  map +($$_[0], $#{$$_[1]} ? $$_[1] : $$_[1][0]),
  map [$$_[0], [split /\|/, $$_[1]]],
  map [split /=/], split /,\s*/,
  $_[1] || ''
}

method decode(Str $data) {
  return $self->encoder->decode($data);
}

method drop(Any @args) {
  $self->throw(error_not_implemented($self, 'drop'));
}

method encode(HashRef $data) {
  return $self->encoder->encode($data);
}

method keys(Any @args) {
  $self->throw(error_not_implemented($self, 'keys'));
}

method lpull(Any @args) {
  $self->throw(error_not_implemented($self, 'lpull'));
}

method lpush(Any @args) {
  $self->throw(error_not_implemented($self, 'lpush'));
}

method recv(Any @args) {
  $self->throw(error_not_implemented($self, 'recv'));
}

method rpull(Any @args) {
  $self->throw(error_not_implemented($self, 'rpull'));
}

method rpush(Any @args) {
  $self->throw(error_not_implemented($self, 'rpush'));
}

method send(Any @args) {
  $self->throw(error_not_implemented($self, 'send'));
}

method size(Any @args) {
  $self->throw(error_not_implemented($self, 'size'));
}

method slot(Any @args) {
  $self->throw(error_not_implemented($self, 'slot'));
}

sub term {
  shift; return join(':', @_);
}

method test(Any @args) {
  $self->throw(error_not_implemented($self, 'test'));
}

# ERRORS

fun error_not_implemented(Object $object, Str $method) {
  code => 'error_not_implemented',
  message => "@{[ref($object)]} method \"$method\" not implemented",
}

1;

=encoding utf8

=head1 NAME

Zing::Store - Storage Abstraction

=cut

=head1 ABSTRACT

Data Storage Abstraction

=cut

=head1 SYNOPSIS

  use Zing::Store;

  my $store = Zing::Store->new;

  # $store->drop;

=cut

=head1 DESCRIPTION

This package provides a data persistence interface to be implemented by data
storage abstractions.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Zing::Entity>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Zing::Types>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 encoder

  encoder(Encoder)

This attribute is read-only, accepts C<(Encoder)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 args

  args(Str $env) : (Any)

The args method parses strings with key/value data (typically from an
environment variable) meant to be used in object construction.

=over 4

=item args example #1

  # given: synopsis

  [$store->args('port=0001,debug=0')]

=back

=over 4

=item args example #2

  # given: synopsis

  [$store->args('ports=0001|0002,debug=0')]

=back

=cut

=head2 decode

  decode(Str $data) : HashRef

The decode method should decode the data provided and returns the data as a
hashref.

=over 4

=item decode example #1

  # given: synopsis

  $store->decode('{ status => "ok" }');

  # e.g.
  # $ENV{ZING_ENCODER} # Zing::Encoder::Dump

=back

=cut

=head2 drop

  drop(Str $key) : Int

The drop method should remove items from the datastore by key.

=over 4

=item drop example #1

  # given: synopsis

  $store->drop('model');

=back

=cut

=head2 encode

  encode(HashRef $data) : Str

The encode method should encode and return the data provided in a format
suitable for the underlying storage mechanism.

=over 4

=item encode example #1

  # given: synopsis

  $store->encode({ status => 'ok' });

=back

=cut

=head2 keys

  keys(Str @keys) : ArrayRef[Str]

The keys method should return a list of keys under the namespace provided
including itself.

=over 4

=item keys example #1

  # given: synopsis

  my $keys = $store->keys('zing:main:global:model:temp');

=back

=cut

=head2 lpull

  lpull(Str $key) : Maybe[HashRef]

The lpull method should pop data off of the top of a list in the datastore.

=over 4

=item lpull example #1

  # given: synopsis

  $store->lpull('zing:main:global:model:items');

=back

=cut

=head2 lpush

  lpush(Str $key) : Int

The lpush method should push data onto the top of a list in the datastore.

=over 4

=item lpush example #1

  # given: synopsis

  # $store->rpush('zing:main:global:model:items', { status => '1' });
  # $store->rpush('zing:main:global:model:items', { status => '2' });

  $store->lpush('zing:main:global:model:items', { status => '0' });

=back

=cut

=head2 recv

  recv(Str $key) : Maybe[HashRef]

The recv method should fetch and return data from the datastore by its key.

=over 4

=item recv example #1

  # given: synopsis

  $store->recv('zing:main:global:model:temp');

=back

=cut

=head2 rpull

  rpull(Str $key) : Maybe[HashRef]

The rpull method should pop data off of the bottom of a list in the datastore.

=over 4

=item rpull example #1

  # given: synopsis

  $store->rpull('zing:main:global:model:items');

=back

=cut

=head2 rpush

  rpush(Str $key, HashRef $val) : Int

The rpush method should push data onto the bottom of a list in the datastore.

=over 4

=item rpush example #1

  # given: synopsis

  $store->rpush('zing:main:global:model:items', { status => 'ok' });

=back

=cut

=head2 send

  send(Str $key, HashRef $val) : Str

The send method should commit data to the datastore with its key and return
truthy (or falsy if not).

=over 4

=item send example #1

  # given: synopsis

  $store->send('zing:main:global:model:temp', { status => 'ok' });

=back

=cut

=head2 size

  size(Str $key) : Int

The size method should return the size of a list in the datastore.

=over 4

=item size example #1

  # given: synopsis

  my $size = $store->size('zing:main:global:model:items');

=back

=cut

=head2 slot

  slot(Str $key, Int $pos) : Maybe[HashRef]

The slot method should return the data from a list in the datastore by its
position in the list.

=over 4

=item slot example #1

  # given: synopsis

  my $model = $store->slot('zing:main:global:model:items', 0);

=back

=cut

=head2 test

  test(Str $key) : Int

The test method should return truthy if the specific key exists in the
datastore.

=over 4

=item test example #1

  # given: synopsis

  # $store->rpush('zing:main:global:model:items', { status => 'ok' });

  $store->test('zing:main:global:model:items');

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
