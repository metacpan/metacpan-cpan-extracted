package Zing::Store::Redis;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

extends 'Zing::Store';

our $VERSION = '0.01'; # VERSION

# ATTRIBUTES

has client => (
  is => 'ro',
  isa => 'InstanceOf["Redis"]',
  new => 1,
);

fun new_client($self) {
  require Redis;
  state $client = Redis->new($self->args($ENV{ZING_REDIS}));
}

# BUILDERS

fun new_encoder($self) {
  require Zing::Encoder::Json; Zing::Encoder::Json->new;
}

# METHODS

method drop(Str $key) {
  return $self->client->del($key);
}

method keys(Str $query) {
  return [$self->client->keys($query)];
}

method lpull(Str $key) {
  my $get = $self->client->lpop($key);
  return $get ? $self->decode($get) : $get;
}

method lpush(Str $key, HashRef $val) {
  my $set = $self->encode($val);
  return $self->client->lpush($key, $set);
}

method recv(Str $key) {
  my $get = $self->client->get($key);
  return $get ? $self->decode($get) : $get;
}

method rpull(Str $key) {
  my $get = $self->client->rpop($key);
  return $get ? $self->decode($get) : $get;
}

method rpush(Str $key, HashRef $val) {
  my $set = $self->encode($val);
  return $self->client->rpush($key, $set);
}

method send(Str $key, HashRef $val) {
  my $set = $self->encode($val);
  return $self->client->set($key, $set);
}

method size(Str $key) {
  return $self->client->llen($key);
}

method slot(Str $key, Int $pos) {
  my $get = $self->client->lindex($key, $pos);
  return $get ? $self->decode($get) : $get;
}

method test(Str $key) {
  return $self->client->exists($key) ? 1 : 0;
}

1;

=encoding utf8

=head1 NAME

Zing::Store::Redis - Redis Storage

=cut

=head1 ABSTRACT

Redis Storage Abstraction

=cut

=head1 SYNOPSIS

  use Zing::Store::Redis;
  use Zing::Encoder::Dump;

  my $redis = Zing::Store::Redis->new(
    encoder => Zing::Encoder::Dump->new
  );

  # $redis->drop;

=cut

=head1 DESCRIPTION

This package provides a L<Redis> storage adapter for use with data persistence
abstractions.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Zing::Store>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Zing::Types>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 client

  client(InstanceOf["Redis"])

This attribute is read-only, accepts C<(InstanceOf["Redis"])> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 decode

  decode(Str $data) : HashRef

The decode method decodes the JSON data provided and returns the data as a hashref.

=over 4

=item decode example #1

  # given: synopsis

  $redis->decode('{"status"=>"ok"}');

=back

=cut

=head2 drop

  drop(Str $key) : Int

The drop method removes (drops) the item from the datastore.

=over 4

=item drop example #1

  # given: synopsis

  $redis->drop('zing:main:global:model:temp');

=back

=cut

=head2 encode

  encode(HashRef $data) : Str

The encode method encodes and returns the data provided as JSON.

=over 4

=item encode example #1

  # given: synopsis

  $redis->encode({ status => 'ok' });

=back

=cut

=head2 keys

  keys(Str @keys) : ArrayRef[Str]

The keys method returns a list of keys under the namespace of the datastore or
provided key.

=over 4

=item keys example #1

  # given: synopsis

  my $keys = $redis->keys('zing:main:global:model:temp');

=back

=over 4

=item keys example #2

  # given: synopsis

  $redis->send('zing:main:global:model:temp', { status => 'ok' });

  my $keys = $redis->keys('zing:main:global:model:temp');

=back

=cut

=head2 lpull

  lpull(Str $key) : Maybe[HashRef]

The lpull method pops data off of the top of a list in the datastore.

=over 4

=item lpull example #1

  # given: synopsis

  $redis->lpull('zing:main:global:model:items');

=back

=over 4

=item lpull example #2

  # given: synopsis

  $redis->rpush('zing:main:global:model:items', { status => 'ok' });

  $redis->lpull('zing:main:global:model:items');

=back

=cut

=head2 lpush

  lpush(Str $key, HashRef $val) : Int

The lpush method pushed data onto the top of a list in the datastore.

=over 4

=item lpush example #1

  # given: synopsis

  $redis->lpush('zing:main:global:model:items', { status => '1' });

=back

=over 4

=item lpush example #2

  # given: synopsis

  $redis->lpush('zing:main:global:model:items', { status => '0' });

=back

=cut

=head2 recv

  recv(Str $key) : Maybe[HashRef]

The recv method fetches and returns data from the datastore by its key.

=over 4

=item recv example #1

  # given: synopsis

  $redis->recv('zing:main:global:model:temp');

=back

=over 4

=item recv example #2

  # given: synopsis

  $redis->send('zing:main:global:model:temp', { status => 'ok' });

  $redis->recv('zing:main:global:model:temp');

=back

=cut

=head2 rpull

  rpull(Str $key) : Maybe[HashRef]

The rpull method pops data off of the bottom of a list in the datastore.

=over 4

=item rpull example #1

  # given: synopsis

  $redis->rpull('zing:main:global:model:items');

=back

=over 4

=item rpull example #2

  # given: synopsis

  $redis->rpush('zing:main:global:model:items', { status => 1 });
  $redis->rpush('zing:main:global:model:items', { status => 2 });

  $redis->rpull('zing:main:global:model:items');

=back

=cut

=head2 rpush

  rpush(Str $key, HashRef $val) : Int

The rpush method pushed data onto the bottom of a list in the datastore.

=over 4

=item rpush example #1

  # given: synopsis

  $redis->rpush('zing:main:global:model:items', { status => 'ok' });

=back

=over 4

=item rpush example #2

  # given: synopsis

  $redis->rpush('zing:main:global:model:items', { status => 'ok' });

  $redis->rpush('zing:main:global:model:items', { status => 'ok' });

=back

=cut

=head2 send

  send(Str $key, HashRef $val) : Str

The send method commits data to the datastore with its key and returns truthy.

=over 4

=item send example #1

  # given: synopsis

  $redis->send('zing:main:global:model:temp', { status => 'ok' });

=back

=cut

=head2 size

  size(Str $key) : Int

The size method returns the size of a list in the datastore.

=over 4

=item size example #1

  # given: synopsis

  my $size = $redis->size('zing:main:global:model:items');

=back

=over 4

=item size example #2

  # given: synopsis

  $redis->rpush('zing:main:global:model:items', { status => 'ok' });

  my $size = $redis->size('zing:main:global:model:items');

=back

=cut

=head2 slot

  slot(Str $key, Int $pos) : Maybe[HashRef]

The slot method returns the data from a list in the datastore by its index.

=over 4

=item slot example #1

  # given: synopsis

  my $model = $redis->slot('zing:main:global:model:items', 0);

=back

=over 4

=item slot example #2

  # given: synopsis

  $redis->rpush('zing:main:global:model:items', { status => 'ok' });

  my $model = $redis->slot('zing:main:global:model:items', 0);

=back

=cut

=head2 test

  test(Str $key) : Int

The test method returns truthy if the specific key (or datastore) exists.

=over 4

=item test example #1

  # given: synopsis

  $redis->rpush('zing:main:global:model:items', { status => 'ok' });

  $redis->test('zing:main:global:model:items');

=back

=over 4

=item test example #2

  # given: synopsis

  $redis->drop('zing:main:global:model:items');

  $redis->test('zing:main:global:model:items');

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/zing-store-redis/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/zing-store-redis/wiki>

L<Project|https://github.com/iamalnewkirk/zing-store-redis>

L<Initiatives|https://github.com/iamalnewkirk/zing-store-redis/projects>

L<Milestones|https://github.com/iamalnewkirk/zing-store-redis/milestones>

L<Contributing|https://github.com/iamalnewkirk/zing-store-redis/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/zing-store-redis/issues>

=cut