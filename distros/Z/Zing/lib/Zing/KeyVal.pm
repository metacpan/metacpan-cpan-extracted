package Zing::KeyVal;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;

extends 'Zing::Repo';

use Zing::Poll;
use Zing::Term;

our $VERSION = '0.12'; # VERSION

# METHODS

method poll(Str $key) {
  return Zing::Poll->new(repo => $self, name => $key);
}

method recv(Str $key) {
  return $self->store->recv($self->term($key));
}

method send(Str $key, HashRef $val) {
  return $self->store->send($self->term($key), $val);
}

method term(Str @keys) {
  return Zing::Term->new($self, @keys)->keyval;
}

1;

=encoding utf8

=head1 NAME

Zing::KeyVal - Key/Value Store

=cut

=head1 ABSTRACT

Generic Key/Value Store

=cut

=head1 SYNOPSIS

  use Zing::KeyVal;

  my $keyval = Zing::KeyVal->new(name => 'notes');

  # $keyval->recv('today');

=cut

=head1 DESCRIPTION

This package provides a general-purpose key/value store abstraction.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Zing::Repo>

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

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 poll

  poll(Str $key) : Poll

The poll method returns a L<Zing::Poll> object which can be used to perform a
blocking-fetch from the store.

=over 4

=item poll example #1

  # given: synopsis

  $keyval->poll('today');

=back

=cut

=head2 recv

  recv(Str $key) : Maybe[HashRef]

The recv method fetches the data (if any) from the store.

=over 4

=item recv example #1

  # given: synopsis

  $keyval->recv('today');

=back

=over 4

=item recv example #2

  # given: synopsis

  $keyval->send('today', { status => 'happy' });

  $keyval->recv('today');

=back

=cut

=head2 send

  send(Str $key, HashRef $value) : Str

The send method commits data to the store overwriting any existing data.

=over 4

=item send example #1

  # given: synopsis

  $keyval->send('today', { status => 'happy' });

=back

=over 4

=item send example #2

  # given: synopsis

  $keyval->drop;

  $keyval->send('today', { status => 'happy' });

=back

=cut

=head2 term

  term(Str @keys) : Str

The term method generates a term (safe string) for the datastore.

=over 4

=item term example #1

  # given: synopsis

  $keyval->term('today');

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
