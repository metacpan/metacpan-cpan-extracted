package Zing::Repo;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;
use Data::Object::Space;

use Zing::Server;
use Zing::Store;
use Zing::Term;

our $VERSION = '0.12'; # VERSION

# ATTRIBUTES

has 'name' => (
  is => 'ro',
  isa => 'Str',
  req => 1,
);

has 'server' => (
  is => 'ro',
  isa => 'Server',
  new => 1,
);

fun new_server($self) {
  Zing::Server->new
}

has 'store' => (
  is => 'ro',
  isa => 'Store',
  new => 1,
);

fun new_store($self) {
  Data::Object::Space->new($ENV{ZING_STORE} || 'Zing::Redis')->build
}

has 'target' => (
  is => 'ro',
  isa => 'Enum[qw(global local)]',
  new => 1,
);

fun new_target($self) {
  'local'
}

# METHODS

method drop(Str @keys) {
  return $self->store->drop($self->term(@keys));
}

method ids() {
  return $self->store->keys($self->term);
}

method keys() {
  return [map {my $re = quotemeta $self->term; s/^$re://r} @{$self->ids}];
}

method term(Str @keys) {
  return Zing::Term->new($self, @keys)->repo;
}

method test(Str @keys) {
  return $self->store->test($self->term(@keys));
}

1;

=encoding utf8

=head1 NAME

Zing::Repo - Generic Store

=cut

=head1 ABSTRACT

Generic Store Abstraction

=cut

=head1 SYNOPSIS

  use Zing::Repo;

  my $repo = Zing::Repo->new(name => 'repo');

  # $repo->recv('text-1');

=cut

=head1 DESCRIPTION

This package provides a general-purpose data storage abstraction.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Zing::Types>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 name

  name(Str)

This attribute is read-only, accepts C<(Str)> values, and is required.

=cut

=head2 server

  server(Server)

This attribute is read-only, accepts C<(Server)> values, and is optional.

=cut

=head2 store

  store(Store)

This attribute is read-only, accepts C<(Store)> values, and is optional.

=cut

=head2 target

  target(Enum[qw(global local)])

This attribute is read-only, accepts C<(Enum[qw(global local)])> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 drop

  drop(Str @keys) : Int

The drop method returns truthy if the data was removed from the store.

=over 4

=item drop example #1

  # given: synopsis

  $repo->drop('text-1');

=back

=cut

=head2 ids

  ids() : ArrayRef[Str]

The ids method returns a list of IDs (keys) stored under the datastore namespace.

=over 4

=item ids example #1

  # given: synopsis

  my $ids = $repo->ids;

=back

=cut

=head2 keys

  keys() : ArrayRef[Str]

The keys method returns a list of fully-qualified keys stored under the
datastore namespace.

=over 4

=item keys example #1

  # given: synopsis

  my $keys = $repo->keys;

=back

=cut

=head2 term

  term(Str @keys) : Str

The term method generates a term (safe string) for the datastore.

=over 4

=item term example #1

  # given: synopsis

  my $term = $repo->term('text-1');

=back

=cut

=head2 test

  test(Str @keys) : Int

The test method returns truthy if the specific key (or datastore) exists.

=over 4

=item test example #1

  # given: synopsis

  $repo->test('text-1');

=back

=over 4

=item test example #2

  # given: synopsis

  $repo->store->send($repo->term('text-1'), { test => time });

  $repo->test('text-1');

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
