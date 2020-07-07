package Zing::Store;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Class;

use Carp ();

our $VERSION = '0.12'; # VERSION

# METHODS

sub args {
  map +($$_[0], $#{$$_[1]} ? $$_[1] : $$_[1][0]),
  map [$$_[0], [split /\|/, $$_[1]]],
  map [split /=/], split /,\s*/,
  $_[1] || ''
}

sub drop {
  Carp::croak qq(Error in Store: (@{[ref$_[0]]}) method "drop" not implemented);
}

sub dump {
  Carp::croak qq(Error in Store: (@{[ref$_[0]]}) method "dump" not implemented);
}

sub keys {
  Carp::croak qq(Error in Store: (@{[ref$_[0]]}) method "keys" not implemented);
}

sub load {
  Carp::croak qq(Error in Store: (@{[ref$_[0]]}) method "load" not implemented);
}

sub lpull {
  Carp::croak qq(Error in Store: (@{[ref$_[0]]}) method "lpull" not implemented);
}

sub lpush {
  Carp::croak qq(Error in Store: (@{[ref$_[0]]}) method "lpush" not implemented);
}

sub recv {
  Carp::croak qq(Error in Store: (@{[ref$_[0]]}) method "recv" not implemented);
}

sub rpull {
  Carp::croak qq(Error in Store: (@{[ref$_[0]]}) method "rpull" not implemented);
}

sub rpush {
  Carp::croak qq(Error in Store: (@{[ref$_[0]]}) method "rpush" not implemented);
}

sub send {
  Carp::croak qq(Error in Store: (@{[ref$_[0]]}) method "send" not implemented);
}

sub size {
  Carp::croak qq(Error in Store: (@{[ref$_[0]]}) method "size" not implemented);
}

sub slot {
  Carp::croak qq(Error in Store: (@{[ref$_[0]]}) method "slot" not implemented);
}

sub term {
  shift; return join(':', @_);
}

sub test {
  Carp::croak qq(Error in Store: (@{[ref$_[0]]}) method "test" not implemented);
}

1;

=encoding utf8

=head1 NAME

Zing::Store - Storage Interface

=cut

=head1 ABSTRACT

Data Storage Interface

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

=head1 LIBRARIES

This package uses type constraints from:

L<Zing::Types>

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

=head2 drop

  drop(Str $key) : Int

The drop method should remove items from the datastore by key.

=over 4

=item drop example #1

  # given: synopsis

  $store->drop('model');

=back

=cut

=head2 dump

  dump(HashRef $data) : Str

The dump method should encode and return the data provided in a format suitable
for the underlying storage mechanism.

=over 4

=item dump example #1

  # given: synopsis

  $store->dump({ status => 'ok' });

=back

=cut

=head2 keys

  keys(Str @keys) : ArrayRef[Str]

The keys method should return a list of keys under the namespace provided
including itself.

=over 4

=item keys example #1

  # given: synopsis

  my $keys = $store->keys('nodel');

=back

=over 4

=item keys example #2

  # given: synopsis

  # $store->send('model', { status => 'ok' });

  my $keys = $store->keys('model');

=back

=cut

=head2 load

  load(Str $data) : HashRef

The load method should decode the data provided and returns the data as a
hashref.

=over 4

=item load example #1

  # given: synopsis

  $store->load('{"status":"ok"}');

=back

=cut

=head2 lpull

  lpull(Str $key) : Maybe[HashRef]

The lpull method should pop data off of the top of a list in the datastore.

=over 4

=item lpull example #1

  # given: synopsis

  $store->lpull('collection');

=back

=over 4

=item lpull example #2

  # given: synopsis

  # $store->rpush('collection', { status => 'ok' });

  $store->lpull('collection');

=back

=cut

=head2 lpush

  lpush(Str $key) : Int

The lpush method should push data onto the top of a list in the datastore.

=over 4

=item lpush example #1

  # given: synopsis

  # $store->rpush('collection', { status => '1' });
  # $store->rpush('collection', { status => '2' });

  $store->lpush('collection', { status => '0' });

=back

=cut

=head2 recv

  recv(Str $key) : Maybe[HashRef]

The recv method should fetch and return data from the datastore by its key.

=over 4

=item recv example #1

  # given: synopsis

  $store->recv('model');

=back

=over 4

=item recv example #2

  # given: synopsis

  # $store->send('model', { status => 'ok' });

  $store->recv('model');

=back

=cut

=head2 rpull

  rpull(Str $key) : Maybe[HashRef]

The rpull method should pop data off of the bottom of a list in the datastore.

=over 4

=item rpull example #1

  # given: synopsis

  $store->rpull('collection');

=back

=over 4

=item rpull example #2

  # given: synopsis

  # $store->rpush('collection', { status => 1 });
  # $store->rpush('collection', { status => 2 });

  $store->rpull('collection');

=back

=cut

=head2 rpush

  rpush(Str $key, HashRef $val) : Int

The rpush method should push data onto the bottom of a list in the datastore.

=over 4

=item rpush example #1

  # given: synopsis

  $store->rpush('collection', { status => 'ok' });

=back

=cut

=head2 send

  send(Str $key, HashRef $val) : Str

The send method should commit data to the datastore with its key and return
truthy (or falsy if not).

=over 4

=item send example #1

  # given: synopsis

  $store->send('model', { status => 'ok' });

=back

=cut

=head2 size

  size(Str $key) : Int

The size method should return the size of a list in the datastore.

=over 4

=item size example #1

  # given: synopsis

  my $size = $store->size('collection');

=back

=over 4

=item size example #2

  # given: synopsis

  # $store->rpush('collection', { status => 'ok' });

  my $size = $store->size('collection');

=back

=cut

=head2 slot

  slot(Str $key, Int $pos) : Maybe[HashRef]

The slot method should return the data from a list in the datastore by its
position in the list.

=over 4

=item slot example #1

  # given: synopsis

  my $model = $store->slot('collection', 0);

=back

=over 4

=item slot example #2

  # given: synopsis

  # $store->rpush('collection', { status => 'ok' });

  my $model = $store->slot('collection', 0);

=back

=cut

=head2 term

  term(Str @keys) : Str

The term method generates a term (safe string) for the datastore. This method
doesn't need to be implemented.

=over 4

=item term example #1

  # given: synopsis

  $store->term('model');

=back

=cut

=head2 test

  test(Str $key) : Int

The test method should return truthy if the specific key exists in the
datastore.

=over 4

=item test example #1

  # given: synopsis

  # $store->rpush('collection', { status => 'ok' });

  $store->test('collection');

=back

=over 4

=item test example #2

  # given: synopsis

  # $store->drop('collection');

  $store->test('collection');

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
