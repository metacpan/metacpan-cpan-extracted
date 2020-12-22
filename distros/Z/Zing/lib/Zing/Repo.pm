package Zing::Repo;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;
use Data::Object::Space;

extends 'Zing::Entity';

use Zing::Store;
use Zing::Term;

our $VERSION = '0.20'; # VERSION

# ATTRIBUTES

has 'name' => (
  is => 'ro',
  isa => 'Name',
  req => 1,
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

method drop() {
  return $self->store->drop($self->term);
}

method search() {
  $self->app->search(store => $self->store)->using($self);
}

method term() {
  return $self->app->term($self)->repo;
}

method test(Str @keys) {
  return $self->store->test($self->term);
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

  my $repo = Zing::Repo->new(name => 'text');

  # $repo->recv;

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

=head2 store

  store(Store)

This attribute is read-only, accepts C<(Store)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 drop

  drop() : Int

The drop method returns truthy if the data was removed from the store.

=over 4

=item drop example #1

  # given: synopsis

  $repo->drop('text-1');

=back

=cut

=head2 search

  search() : Search

The search method returns a L<Zing::Search> object based on the current repo or
L<Zing::Repo> derived object.

=over 4

=item search example #1

  # given: synopsis

  my $search = $repo->search;

=back

=cut

=head2 term

  term() : Str

The term method generates a term (safe string) for the datastore.

=over 4

=item term example #1

  # given: synopsis

  my $term = $repo->term;

=back

=cut

=head2 test

  test() : Int

The test method returns truthy if the specific key (or datastore) exists.

=over 4

=item test example #1

  # given: synopsis

  $repo->test;

=back

=over 4

=item test example #2

  # given: synopsis

  $repo->store->send($repo->term, { test => time });

  $repo->test;

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
