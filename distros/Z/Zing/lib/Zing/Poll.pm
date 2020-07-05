package Zing::Poll;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

use Time::HiRes ();

our $VERSION = '0.10'; # VERSION

# ATTRIBUTES

has 'name' => (
  is => 'ro',
  isa => 'Str',
  req => 1,
);

has 'repo' => (
  is => 'ro',
  isa => 'Repo',
  req => 1,
);

# METHODS

method await(Int $secs) {
  my $data;
  my $name = $self->name;
  my $repo = $self->repo;
  my @tres = (Time::HiRes::gettimeofday);
  my $time = join('', $tres[0] + $secs, $tres[1]);

  until ($data = $repo->recv($name)) {
    last if join('', Time::HiRes::gettimeofday) >= $time;
  }

  return $data;
}

1;

=encoding utf8

=head1 NAME

Zing::Poll - Blocking Receive

=cut

=head1 ABSTRACT

Blocking Receive Construct

=cut

=head1 SYNOPSIS

  use Zing::Poll;
  use Zing::KeyVal;

  my $keyval = Zing::KeyVal->new(name => 'notes');
  my $poll = Zing::Poll->new(name => 'last-week', repo => $keyval);

=cut

=head1 DESCRIPTION

This package provides an algorithm for preforming a blocking receive by polling
the datastore for a specific item.

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

=head2 repo

  repo(Repo)

This attribute is read-only, accepts C<(Repo)> values, and is required.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 await

  await(Int $secs) : Maybe[HashRef]

The await method polls the datastore specified for the data at the key
specified, for at-least the number of seconds specified, and returns the data
or undefined.

=over 4

=item await example #1

  # given: synopsis

  $poll->await(0);

=back

=over 4

=item await example #2

  # given: synopsis

  $poll->repo->send('last-week', { task => 'write research paper' });

  $poll->await(0);

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
