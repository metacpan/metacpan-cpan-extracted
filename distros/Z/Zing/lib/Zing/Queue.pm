package Zing::Queue;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;

extends 'Zing::PubSub';

use Zing::Term;

our $VERSION = '0.10'; # VERSION

# METHODS

method recv() {
  return $self->store->pull($self->term);
}

method send(HashRef $val) {
  return $self->store->push($self->term, $val);
}

method size() {
  return $self->store->size($self->term);
}

method term() {
  return Zing::Term->new($self)->queue;
}

1;

=encoding utf8

=head1 NAME

Zing::Queue - Message Queue

=cut

=head1 ABSTRACT

Generic Message Queue

=cut

=head1 SYNOPSIS

  use Zing::Queue;

  my $queue = Zing::Queue->new(name => 'tasks');

  # $queue->recv;

=cut

=head1 DESCRIPTION

This package provides a general-purpose message queue abstraction.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Zing::PubSub>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Zing::Types>

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 recv

  recv() : Maybe[HashRef]

The recv method receives a single new message from the channel.

=over 4

=item recv example #1

  # given: synopsis

  $queue->recv;

=back

=over 4

=item recv example #2

  # given: synopsis

  $queue->send({ restart => { after => 'cleanup' }});

  $queue->recv;

=back

=cut

=head2 send

  send(HashRef $value) : Int

The send method sends a new message to the queue and returns the message count.

=over 4

=item send example #1

  # given: synopsis

  $queue->send({ restart => { after => 'cleanup' }});

=back

=over 4

=item send example #2

  # given: synopsis

  $queue->drop;

  $queue->send({ restart => { after => 'cleanup' }});

=back

=cut

=head2 size

  size() : Int

The size method returns the number of messages in the queue.

=over 4

=item size example #1

  # given: synopsis

  my $size = $queue->size;

=back

=cut

=head2 term

  term() : Str

The term method generates a term (safe string) for the queue.

=over 4

=item term example #1

  # given: synopsis

  $queue->term;

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
