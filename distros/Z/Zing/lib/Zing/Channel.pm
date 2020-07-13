package Zing::Channel;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;

extends 'Zing::PubSub';

use Zing::Term;

our $VERSION = '0.13'; # VERSION

# BUILDERS

fun BUILD($self) {
  $self->{cursor} = $self->size;

  return $self;
}

# METHODS

method recv() {
  $self->{cursor}++ if (
    my $data = $self->store->slot($self->term, int($self->{cursor}))
  );
  return $data;
}

method renew() {
  return !($self->{cursor} = 0) if $self->{cursor} > $self->size;
  return 0;
}

method reset() {
  return !($self->{cursor} = 0);
}

method send(HashRef $val) {
  return $self->store->rpush($self->term, $val);
}

method size() {
  return $self->store->size($self->term);
}

method term() {
  return Zing::Term->new($self)->channel;
}

1;

=encoding utf8

=head1 NAME

Zing::Channel - Shared Communication

=cut

=head1 ABSTRACT

Multi-process Communication Mechanism

=cut

=head1 SYNOPSIS

  use Zing::Channel;

  my $chan = Zing::Channel->new(name => 'share');

  # $chan->recv;

=cut

=head1 DESCRIPTION

This package provides represents a mechanism of interprocess communication and
synchronization via message passing.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Zing::PubSub>

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

=head2 recv

  recv() : Maybe[HashRef]

The recv method receives a single new message from the channel.

=over 4

=item recv example #1

  my $chan = Zing::Channel->new(name => 'recv-01');

  $chan->recv;

=back

=over 4

=item recv example #2

  my $chan = Zing::Channel->new(name => 'recv-02');

  $chan->send({ status => 'works' });

  $chan->recv;

=back

=cut

=head2 renew

  renew() : Int

The renew method returns truthy if it resets the internal cursor, otherwise
falsy.

=over 4

=item renew example #1

  my $chan = Zing::Channel->new(name => 'renew-01');

  $chan->send({ status => 'works' }) for 1..5;

  $chan->renew;

=back

=over 4

=item renew example #2

  my $chan = Zing::Channel->new(name => 'renew-02');

  $chan->send({ status => 'works' }) for 1..5;
  $chan->recv;
  $chan->drop;

  $chan->renew;

=back

=cut

=head2 reset

  reset() : Int

The reset method always reset the internal cursor and return truthy.

=over 4

=item reset example #1

  my $chan = Zing::Channel->new(name => 'reset-01');

  $chan->send({ status => 'works' }) for 1..5;
  $chan->recv;
  $chan->recv;

  $chan->reset;

=back

=cut

=head2 send

  send(HashRef $value) : Int

The send method sends a new message to the channel and return the message
count.

=over 4

=item send example #1

  my $chan = Zing::Channel->new(name => 'send-01');

  $chan->send({ status => 'works' });

=back

=cut

=head2 size

  size() : Int

The size method returns the message count of the channel.

=over 4

=item size example #1

  my $chan = Zing::Channel->new(name => 'size-01');

  $chan->send({ status => 'works' }) for 1..5;

  $chan->size;

=back

=cut

=head2 term

  term() : Str

The term method returns the name of the channel.

=over 4

=item term example #1

  my $chan = Zing::Channel->new(name => 'term-01');

  $chan->term;

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
