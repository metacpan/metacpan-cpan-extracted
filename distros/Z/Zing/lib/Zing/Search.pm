package Zing::Search;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

extends 'Zing::Entity';

our $VERSION = '0.22'; # VERSION

# ATTRIBUTES

has 'handle' => (
  is => 'rw',
  isa => 'Str',
  def => '*',
);

has 'symbol' => (
  is => 'rw',
  isa => 'Str',
  def => '*',
);

has 'bucket' => (
  is => 'rw',
  isa => 'Str',
  def => '*',
);

has 'system' => (
  is => 'rw',
  isa => 'Name',
  def => 'zing',
);

has 'target' => (
  is => 'rw',
  isa => 'Str',
  def => '*',
);

has 'store' => (
  is => 'ro',
  isa => 'Store',
  new => 1,
);

fun new_store($self) {
  $self->app->store
}

# METHODS

method any() {
  return $self->where(
    bucket => '*',
    symbol => '*',
    handle => '*',
    target => '*',
  );
}

method for(Str $type) {
  return $self->where(
    bucket => '*',
    symbol => lc($type),
    handle => $self->env->handle || '*',
    target => $self->env->target || '*',
  );
}

method objects() {
  my $result = [];

  $self->process(fun($term) {
    push @$result, $self->app->term($term)->object;
  });

  return $result;
}

method process(CodeRef $callback) {
  for my $term (@{$self->results}) {
    $callback->($term);
  }

  return $self;
}

method query() {
  my $system = $self->system || '*';
  my $handle = $self->handle || '*';
  my $target = $self->target || '*';
  my $symbol = $self->symbol || '*';
  my $bucket = $self->bucket || '*';

  return lc join ':', $system, $handle, $target, $symbol, $bucket;
}

method results() {
  return $self->store->keys($self->query);
}

method using(Repo $repo) {
  my $term = $self->app->term($repo);

  return $self->where(
    bucket => $term->bucket,
    handle => $term->handle,
    symbol => $term->symbol,
    system => $term->system,
    target => $term->target,
  );
}

method where(Str %args) {
  $self->$_($args{$_}) for keys %args;

  return $self;
}

1;

=encoding utf8

=head1 NAME

Zing::Search - Search Abstraction

=cut

=head1 ABSTRACT

Storage Search Abstraction

=cut

=head1 SYNOPSIS

  use Zing::Search;

  my $search = Zing::Search->new;

  # $search->query;

=cut

=head1 DESCRIPTION

This package provides a storage search abstraction.

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

=head2 bucket

  bucket(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 handle

  handle(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 store

  store(Store)

This attribute is read-only, accepts C<(Store)> values, and is optional.

=cut

=head2 symbol

  symbol(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 system

  system(Name)

This attribute is read-only, accepts C<(Name)> values, and is optional.

=cut

=head2 target

  target(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 any

  any() : Object

The any method returns a search to query for any C<handle>, C<target>,
C<symbol> and C<bucket>.

=over 4

=item any example #1

  # given: synopsis

  $search = $search->any;

=back

=cut

=head2 for

  for(Str $type) : Object

The for method returns a search to query for any object of the given type
within the defined C<handle> and C<target>.

=over 4

=item for example #1

  # given: synopsis

  $search = $search->for('queue');

=back

=cut

=head2 objects

  objects() : ArrayRef[Object]

The objects method returns a collection of objects derived from the query
criteria.

=over 4

=item objects example #1

  # given: synopsis

  my $objects = $search->objects;

=back

=over 4

=item objects example #2

  # given: synopsis

  use Zing::KeyVal;
  use Zing::PubSub;

  my $keyval = Zing::KeyVal->new(name => rand);
  $keyval->send({ sent => 1 });

  my $pubsub = Zing::PubSub->new(name => rand);
  $pubsub->send({ sent => 1 });

  my $objects = $search->objects;

=back

=cut

=head2 process

  process(CodeRef $callback) : Object

The process method executes the C<callback> for each term in the search
results.

=over 4

=item process example #1

  # given: synopsis

  $search = $search->process(sub {
    my ($term) = @_;
  });

=back

=cut

=head2 query

  query() : Str

The query method returns the query string used to produce search results.

=over 4

=item query example #1

  # given: synopsis

  my $query = $search->query;

=back

=cut

=head2 results

  results() : ArrayRef[Str]

The results method performs a search and returns a collection of terms that
meet the criteria.

=over 4

=item results example #1

  # given: synopsis

  my $results = $search->results;

=back

=over 4

=item results example #2

  # given: synopsis

  use Zing::KeyVal;
  use Zing::PubSub;

  my $keyval = Zing::KeyVal->new(name => rand);
  $keyval->send({ sent => 1 });

  my $pubsub = Zing::PubSub->new(name => rand);
  $pubsub->send({ sent => 1 });

  my $results = $search->results;

=back

=cut

=head2 using

  using(Repo $repo) : Object

The using method modifies the search criteria to match the term of the
provided repo or L<Zing::Repo> derived object.

=over 4

=item using example #1

  # given: synopsis

  use Zing::Queue;

  my $tasks = Zing::Queue->new(name => 'tasks');

  $search = $search->using($tasks);

=back

=cut

=head2 where

  where(Str %args) : Object

The where method modifies the search criteria based on the arguments
provided.

=over 4

=item where example #1

  # given: synopsis

  $search = $search->where(
    handle => 'myapp',
    target => 'us-west',
  );

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
