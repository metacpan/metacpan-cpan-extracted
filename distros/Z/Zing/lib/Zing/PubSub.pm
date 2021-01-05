package Zing::PubSub;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;

extends 'Zing::Repo';

use Zing::Poll;

our $VERSION = '0.26'; # VERSION

# METHODS

method poll() {
  return Zing::Poll->new(repo => $self);
}

method recv() {
  return $self->store->lpull($self->term);
}

method send(HashRef $value) {
  return $self->store->rpush($self->term, $value);
}

method term() {
  return $self->app->term($self)->pubsub;
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

  # $pubsub->recv;

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

  poll() : Poll

The poll method returns a L<Zing::Poll> object which can be used to perform a
blocking-fetch from the store.

=over 4

=item poll example #1

  # given: synopsis

  $pubsub->poll;

=back

=cut

=head2 recv

  recv() : Maybe[HashRef]

The recv method receives a single new message from the store.

=over 4

=item recv example #1

  # given: synopsis

  $pubsub->recv;

=back

=over 4

=item recv example #2

  # given: synopsis

  $pubsub->send({ task => 'restart' });

  $pubsub->recv;

=back

=cut

=head2 send

  send(Str $key, HashRef $value) : Int

The send method sends a new message to the store and return the message count.

=over 4

=item send example #1

  # given: synopsis

  $pubsub->send({ task => 'restart' });

=back

=over 4

=item send example #2

  # given: synopsis

  $pubsub->drop;

  $pubsub->send({ task => 'stop' });

  $pubsub->send({ task => 'restart' });

=back

=cut

=head2 term

  term(Str @keys) : Str

The term method return a term (safe string) for the store.

=over 4

=item term example #1

  # given: synopsis

  $pubsub->term;

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
