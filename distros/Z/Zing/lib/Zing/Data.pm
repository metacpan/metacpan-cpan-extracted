package Zing::Data;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

extends 'Zing::KeyVal';

use Zing::Term;

our $VERSION = '0.13'; # VERSION

# ATTRIBUTES

has 'name' => (
  is => 'ro',
  isa => 'Str',
  init_arg => undef,
  new => 1,
  mod => 1,
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

fun BUILD($self) {
  $self->{name} = $self->new_name;

  return $self;
}

# METHODS

method recv() {
  return $self->store->recv($self->term);
}

method send(HashRef $val) {
  return $self->store->send($self->term, $val);
}

method term() {
  return Zing::Term->new($self)->data;
}

1;

=encoding utf8

=head1 NAME

Zing::Data - Process Data

=cut

=head1 ABSTRACT

Process Key/Val Data Store

=cut

=head1 SYNOPSIS

  use Zing::Data;
  use Zing::Process;

  my $data = Zing::Data->new(process => Zing::Process->new);

  # $data->recv;

=cut

=head1 DESCRIPTION

This package provides a process-specific key/value store for arbitrary data.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Zing::KeyVal>

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

The recv method fetches the data (if any) from the store.

=over 4

=item recv example #1

  # given: synopsis

  $data->recv;

=back

=over 4

=item recv example #2

  # given: synopsis

  $data->send({ status => 'works' });

  $data->recv;

=back

=cut

=head2 send

  send(HashRef $value) : Str

The send method commits data to the store overwriting any existing data.

=over 4

=item send example #1

  # given: synopsis

  $data->send({ status => 'works' });

=back

=over 4

=item send example #2

  # given: synopsis

  $data->drop;

  $data->send({ status => 'works' });

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
