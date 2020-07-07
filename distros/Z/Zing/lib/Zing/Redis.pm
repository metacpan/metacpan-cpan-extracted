package Zing::Redis;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

extends 'Zing::Store';

use JSON -convert_blessed_universally;

our $VERSION = '0.12'; # VERSION

# ATTRIBUTES

has 'client' => (
  is => 'ro',
  isa => 'Redis',
  new => 1,
);

fun new_client($self) {
  require Redis;
  # e.g. ZING_REDIS='server=127.0.0.1:9999,debug=0'
  state $client = Redis->new($self->args($ENV{ZING_REDIS}));
}

# METHODS

method drop(Str $key) {
  return $self->client->del($key);
}

method dump(HashRef $data) {
  return JSON->new->allow_nonref->convert_blessed->encode($data);
}

method keys(Str @keys) {
  return [map $self->client->keys($self->term(@$_)), [@keys], [@keys, '*']];
}

method load(Str $data) {
  return JSON->new->allow_nonref->convert_blessed->decode($data);
}

method lpull(Str $key) {
  my $get = $self->client->lpop($key);
  return $get ? $self->load($get) : $get;
}

method lpush(Str $key, HashRef $val) {
  my $set = $self->dump($val);
  return $self->client->lpush($key, $set);
}

method recv(Str $key) {
  my $get = $self->client->get($key);
  return $get ? $self->load($get) : $get;
}

method rpull(Str $key) {
  my $get = $self->client->rpop($key);
  return $get ? $self->load($get) : $get;
}

method rpush(Str $key, HashRef $val) {
  my $set = $self->dump($val);
  return $self->client->rpush($key, $set);
}

method send(Str $key, HashRef $val) {
  my $set = $self->dump($val);
  return $self->client->set($key, $set);
}

method size(Str $key) {
  return $self->client->llen($key);
}

method slot(Str $key, Int $pos) {
  my $get = $self->client->lindex($key, $pos);
  return $get ? $self->load($get) : $get;
}

method test(Str $key) {
  return int $self->client->exists($key);
}

1;

=encoding utf8

=head1 NAME

Zing::Redis - Redis Storage

=cut

=head1 ABSTRACT

Redis Storage Abstraction

=cut

=head1 SYNOPSIS

  use Zing::Redis;

  my $redis = Zing::Redis->new;

  # $redis->drop;

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

=head2 client

  client(Redis)

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

  $redis->drop('model');

=back

=cut

=head2 dump

  dump(HashRef $data) : Str

The dump method encodes and returns the data provided as JSON.

=over 4

=item dump example #1

  # given: synopsis

  $redis->dump({ status => 'ok' });

=back

=cut

=head2 keys

  keys(Str @keys) : ArrayRef[Str]

The keys method returns a list of keys under the namespace of the datastore or
provided key.

=over 4

=item keys example #1

  # given: synopsis

  my $keys = $redis->keys('nodel');

=back

=over 4

=item keys example #2

  # given: synopsis

  $redis->send('model', { status => 'ok' });

  my $keys = $redis->keys('model');

=back

=cut

=head2 load

  load(Str $data) : HashRef

The load method decodes the JSON data provided and returns the data as a hashref.

=over 4

=item load example #1

  # given: synopsis

  $redis->load('{"status":"ok"}');

=back

=cut

=head2 lpull

  lpull(Str $key) : Maybe[HashRef]

The lpull method pops data off of the top of a list in the datastore.

=over 4

=item lpull example #1

  # given: synopsis

  $redis->lpull('collection');

=back

=over 4

=item lpull example #2

  # given: synopsis

  $redis->rpush('collection', { status => 'ok' });

  $redis->lpull('collection');

=back

=cut

=head2 lpush

  lpush(Str $key, HashRef $val) : Int

The lpush method pushed data onto the top of a list in the datastore.

=over 4

=item lpush example #1

  # given: synopsis

  $redis->lpush('collection', { status => '1' });

=back

=over 4

=item lpush example #2

  # given: synopsis

  $redis->lpush('collection', { status => '0' });

=back

=cut

=head2 recv

  recv(Str $key) : Maybe[HashRef]

The recv method fetches and returns data from the datastore by its key.

=over 4

=item recv example #1

  # given: synopsis

  $redis->recv('model');

=back

=over 4

=item recv example #2

  # given: synopsis

  $redis->send('model', { status => 'ok' });

  $redis->recv('model');

=back

=cut

=head2 rpull

  rpull(Str $key) : Maybe[HashRef]

The rpull method pops data off of the bottom of a list in the datastore.

=over 4

=item rpull example #1

  # given: synopsis

  $redis->rpull('collection');

=back

=over 4

=item rpull example #2

  # given: synopsis

  $redis->rpush('collection', { status => 1 });
  $redis->rpush('collection', { status => 2 });

  $redis->rpull('collection');

=back

=cut

=head2 rpush

  rpush(Str $key, HashRef $val) : Int

The rpush method pushed data onto the bottom of a list in the datastore.

=over 4

=item rpush example #1

  # given: synopsis

  $redis->rpush('collection', { status => 'ok' });

=back

=over 4

=item rpush example #2

  # given: synopsis

  $redis->rpush('collection', { status => 'ok' });

  $redis->rpush('collection', { status => 'ok' });

=back

=cut

=head2 send

  send(Str $key, HashRef $val) : Str

The send method commits data to the datastore with its key and returns truthy.

=over 4

=item send example #1

  # given: synopsis

  $redis->send('model', { status => 'ok' });

=back

=cut

=head2 size

  size(Str $key) : Int

The size method returns the size of a list in the datastore.

=over 4

=item size example #1

  # given: synopsis

  my $size = $redis->size('collection');

=back

=over 4

=item size example #2

  # given: synopsis

  $redis->rpush('collection', { status => 'ok' });

  my $size = $redis->size('collection');

=back

=cut

=head2 slot

  slot(Str $key, Int $pos) : Maybe[HashRef]

The slot method returns the data from a list in the datastore by its index.

=over 4

=item slot example #1

  # given: synopsis

  my $model = $redis->slot('collection', 0);

=back

=over 4

=item slot example #2

  # given: synopsis

  $redis->rpush('collection', { status => 'ok' });

  my $model = $redis->slot('collection', 0);

=back

=cut

=head2 term

  term(Str @keys) : Str

The term method generates a term (safe string) for the datastore.

=over 4

=item term example #1

  # given: synopsis

  $redis->term('model');

=back

=cut

=head2 test

  test(Str $key) : Int

The test method returns truthy if the specific key (or datastore) exists.

=over 4

=item test example #1

  # given: synopsis

  $redis->rpush('collection', { status => 'ok' });

  $redis->test('collection');

=back

=over 4

=item test example #2

  # given: synopsis

  $redis->drop('collection');

  $redis->test('collection');

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
