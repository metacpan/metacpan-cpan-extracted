package Zing::Mailbox;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

extends 'Zing::PubSub';

use Zing::Term;

our $VERSION = '0.10'; # VERSION

# ATTRIBUTES

has 'name' => (
  is => 'ro',
  isa => 'Str',
  init_arg => undef,
  new => 1,
);

fun new_name($self) {
  $self->process->name
}

has 'process' => (
  is => 'ro',
  isa => 'Process',
  req => 1,
);

# BUILDERS

fun new_target($self) {
  'global'
}

# METHODS

method recv() {
  return $self->store->pull($self->term);
}

method message(HashRef $val) {
  return { data => $val, from => $self->term };
}

method reply(HashRef $bag, HashRef $val) {
  return $self->send($bag->{from}, $val);
}

method send(Str $key, HashRef $val) {
  return $self->store->push($self->term($key), $self->message($val));
}

method size() {
  return $self->store->size($self->term);
}

method term(Maybe[Str] $name) {
  return Zing::Term->new($name || $self)->mailbox;
}

1;

=encoding utf8

=head1 NAME

Zing::Mailbox - Process Mailbox

=cut

=head1 ABSTRACT

Interprocess Communication Mechanism

=cut

=head1 SYNOPSIS

  use Zing::Mailbox;
  use Zing::Process;

  my $mailbox = Zing::Mailbox->new(process => Zing::Process->new);

  # $mailbox->recv;

=cut

=head1 DESCRIPTION

This package provides represents a process mailbox, the default mechanism of
interprocess communication.

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

=head2 process

  process(Process)

This attribute is read-only, accepts C<(Process)> values, and is required.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 recv

  recv() : Maybe[HashRef]

The recv method receives a single new message from the mailbox.

=over 4

=item recv example #1

  # given: synopsis

  $mailbox->recv;

=back

=over 4

=item recv example #2

  # given: synopsis

  $mailbox->send($mailbox->term, { status => 'hello' });

  $mailbox->recv;

=back

=cut

=head2 reply

  reply(HashRef $bag, HashRef $value) : Int

The reply method sends a message to the mailbox represented by the C<$data>
received and returns the size of the recipient mailbox.

=over 4

=item reply example #1

  # given: synopsis

  $mailbox->send($mailbox->term, { status => 'hello' });

  my $data = $mailbox->recv;

  $mailbox->reply($data, { status => 'thank you' });

=back

=cut

=head2 send

  send(Str $key, HashRef $value) : Int

The send method sends a new message to the mailbox specified and returns the
size of the recipient mailbox.

=over 4

=item send example #1

  # given: synopsis

  $mailbox->send($mailbox->term, { status => 'hello' });

=back

=cut

=head2 size

  size() : Int

The size method returns the message count of the mailbox.

=over 4

=item size example #1

  # given: synopsis

  my $size = $mailbox->size;

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
