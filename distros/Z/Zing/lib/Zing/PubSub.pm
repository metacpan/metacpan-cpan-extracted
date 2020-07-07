package Zing::PubSub;

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
  return $self->store->lpull($self->term($key));
}

method send(Str $key, HashRef $val) {
  return $self->store->rpush($self->term($key), $val);
}

method term(Str @keys) {
  return Zing::Term->new($self, @keys)->pubsub;
}

1;

=encoding utf8

=head1 NAME

Zing::PubSub - Pub/Sub Store

=cut

=head1 ABSTRACT

Generic Pub/Sub Store

=cut

=head1 SYNOPSIS

  use Zing::PubSub;

  my $pubsub = Zing::PubSub->new(name => 'tasks');

  # $pubsub->recv('priority-1');

=cut

=head1 DESCRIPTION

This package provides a general-purpose publish/subscribe store abstraction.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Zing::Repo>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Zing::Types>

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

  $pubsub->poll('priority-1');

=back

=cut

=head2 recv

  recv(Str $key) : Maybe[HashRef]

The recv method receives a single new message from the store.

=over 4

=item recv example #1

  # given: synopsis

  $pubsub->recv('priority-1');

=back

=over 4

=item recv example #2

  # given: synopsis

  $pubsub->send('priority-1', { task => 'restart' });

  $pubsub->recv('priority-1');

=back

=cut

=head2 send

  send(Str $key, HashRef $value) : Int

The send method sends a new message to the store and return the message count.

=over 4

=item send example #1

  # given: synopsis

  $pubsub->send('priority-1', { task => 'restart' });

=back

=over 4

=item send example #2

  # given: synopsis

  $pubsub->drop;

  $pubsub->send('priority-1', { task => 'restart' });

=back

=cut

=head2 term

  term(Str @keys) : Str

The term method return a term (safe string) for the store.

=over 4

=item term example #1

  # given: synopsis

  $pubsub->term('priority-1');

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
