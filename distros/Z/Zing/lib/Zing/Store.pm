package Zing::Store;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

use JSON -convert_blessed_universally;

our $VERSION = '0.10'; # VERSION

# ATTRIBUTES

has 'redis' => (
  is => 'ro',
  isa => 'Redis',
  new => 1,
);

fun new_redis($self) {
  require Redis;
  state $redis = Redis->new(
    # e.g. ZING_REDIS='server=127.0.0.1:9999,debug=0'
    map +($$_[0], $#{$$_[1]} ? $$_[1] : $$_[1][0]),
    map [$$_[0], [split /\|/, $$_[1]]],
    map [split /=/], split /,\s*/,
    $ENV{ZING_REDIS} || ''
  );
}

# METHODS

method drop(Str $key) {
  return $self->redis->del($key);
}

method dump(HashRef $data) {
  return JSON->new->allow_nonref->convert_blessed->encode($data);
}

method keys(Str @keys) {
  return [map $self->redis->keys($self->term(@$_)), [@keys], [@keys, '*']];
}

method pop(Str $key) {
  my $get = $self->redis->rpop($key);
  return $get ? $self->load($get) : $get;
}

method pull(Str $key) {
  my $get = $self->redis->lpop($key);
  return $get ? $self->load($get) : $get;
}

method push(Str $key, HashRef $val) {
  my $set = $self->dump($val);
  return $self->redis->rpush($key, $set);
}

method load(Str $data) {
  return JSON->new->allow_nonref->convert_blessed->decode($data);
}

method recv(Str $key) {
  my $get = $self->redis->get($key);
  return $get ? $self->load($get) : $get;
}

method send(Str $key, HashRef $val) {
  my $set = $self->dump($val);
  return $self->redis->set($key, $set);
}

method size(Str $key) {
  return $self->redis->llen($key);
}

method slot(Str $key, Int $pos) {
  my $get = $self->redis->lindex($key, $pos);
  return $get ? $self->load($get) : $get;
}

method term(Str @keys) {
  return join(':', @keys);
}

method test(Str $key) {
  return int $self->redis->exists($key);
}

1;

=encoding utf8

=head1 NAME

Zing::Store - Storage Abstraction

=cut

=head1 ABSTRACT

Redis Storage Abstraction

=cut

=head1 SYNOPSIS

  use Zing::Store;

  my $store = Zing::Store->new;

  # $store->drop;

=cut

=head1 DESCRIPTION

This package provides a L<Redis> adapter for use with data storage
abstractions.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Zing::Types>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 redis

  redis(Redis)

This attribute is read-only, accepts C<(Redis)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 drop

  drop(Str $key) : Int

The drop method removes (drops) the item from the datastore.

=over 4

=item drop example #1

  # given: synopsis

  $store->drop('model');

=back

=cut

=head2 dump

  dump(HashRef $data) : Str

The dump method encodes and returns the data provided as JSON.

=over 4

=item dump example #1

  # given: synopsis

  $store->dump({ status => 'ok' });

=back

=cut

=head2 keys

  keys(Str @keys) : ArrayRef[Str]

The keys method returns a list of keys under the namespace of the datastore or
provided key.

=over 4

=item keys example #1

  # given: synopsis

  my $keys = $store->keys('nodel');

=back

=over 4

=item keys example #2

  # given: synopsis

  $store->send('model', { status => 'ok' });

  my $keys = $store->keys('model');

=back

=cut

=head2 load

  load(Str $data) : HashRef

The load method decodes the JSON data provided and returns the data as a hashref.

=over 4

=item load example #1

  # given: synopsis

  $store->load('{"status":"ok"}');

=back

=cut

=head2 pop

  pop(Str $key) : Maybe[HashRef]

The pop method pops data off of the bottom of a list in the datastore.

=over 4

=item pop example #1

  # given: synopsis

  $store->pop('collection');

=back

=over 4

=item pop example #2

  # given: synopsis

  $store->push('collection', { status => 1 });
  $store->push('collection', { status => 2 });

  $store->pop('collection');

=back

=cut

=head2 pull

  pull(Str $key) : Maybe[HashRef]

The pull method pops data off of the top of a list in the datastore.

=over 4

=item pull example #1

  # given: synopsis

  $store->pull('collection');

=back

=over 4

=item pull example #2

  # given: synopsis

  $store->push('collection', { status => 'ok' });

  $store->pull('collection');

=back

=cut

=head2 push

  push(Str $key, HashRef $val) : Int

The push method pushed data onto the bottom of a list in the datastore.

=over 4

=item push example #1

  # given: synopsis

  $store->push('collection', { status => 'ok' });

=back

=over 4

=item push example #2

  # given: synopsis

  $store->push('collection', { status => 'ok' });

  $store->push('collection', { status => 'ok' });

=back

=cut

=head2 recv

  recv(Str $key) : Maybe[HashRef]

The recv method fetches and returns data from the datastore by its key.

=over 4

=item recv example #1

  # given: synopsis

  $store->recv('model');

=back

=over 4

=item recv example #2

  # given: synopsis

  $store->send('model', { status => 'ok' });

  $store->recv('model');

=back

=cut

=head2 send

  send(Str $key, HashRef $val) : Str

The send method commits data to the datastore with its key and returns truthy.

=over 4

=item send example #1

  # given: synopsis

  $store->send('model', { status => 'ok' });

=back

=cut

=head2 size

  size(Str $key) : Int

The size method returns the size of a list in the datastore.

=over 4

=item size example #1

  # given: synopsis

  my $size = $store->size('collection');

=back

=over 4

=item size example #2

  # given: synopsis

  $store->push('collection', { status => 'ok' });

  my $size = $store->size('collection');

=back

=cut

=head2 slot

  slot(Str $key, Int $pos) : Maybe[HashRef]

The slot method returns the data from a list in the datastore by its index.

=over 4

=item slot example #1

  # given: synopsis

  my $model = $store->slot('collection', 0);

=back

=over 4

=item slot example #2

  # given: synopsis

  $store->push('collection', { status => 'ok' });

  my $model = $store->slot('collection', 0);

=back

=cut

=head2 term

  term(Str @keys) : Str

The term method generates a term (safe string) for the datastore.

=over 4

=item term example #1

  # given: synopsis

  $store->term('model');

=back

=cut

=head2 test

  test(Str $key) : Int

The test method returns truthy if the specific key (or datastore) exists.

=over 4

=item test example #1

  # given: synopsis

  $store->push('collection', { status => 'ok' });

  $store->test('collection');

=back

=over 4

=item test example #2

  # given: synopsis

  $store->drop('collection');

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
