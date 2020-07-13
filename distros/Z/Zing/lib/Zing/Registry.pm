package Zing::Registry;

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
  def => '$default',
  mod => 1,
);

# METHODS

method drop(Process $proc) {
  return $self->store->drop($self->term($proc->name));
}

method recv(Process $proc) {
  return $self->store->recv($self->term($proc->name));
}

method send(Process $proc) {
  return $self->store->send($self->term($proc->name), $proc->metadata);
}

method term(Str @keys) {
  return Zing::Term->new($self, @keys)->registry;
}

1;

=encoding utf8

=head1 NAME

Zing::Registry - Process Registry

=cut

=head1 ABSTRACT

Generic Process Registry

=cut

=head1 SYNOPSIS

  use Zing::Process;
  use Zing::Registry;

  my $process = Zing::Process->new;
  my $registry = Zing::Registry->new(process => $process);

  # $registry->recv($process);

=cut

=head1 DESCRIPTION

This package provides a process registry for tracking active processes.

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

=head1 METHODS

This package implements the following methods:

=cut

=head2 drop

  drop(Process $proc) : Int

The drop method returns truthy if the process can be dropped from the registry.

=over 4

=item drop example #1

  # given: synopsis

  $registry->drop($process);

=back

=cut

=head2 recv

  recv(Process $proc) : Maybe[HashRef]

The recv method fetches the process metadata (if any) from the registry.

=over 4

=item recv example #1

  # given: synopsis

  $registry->recv($process);

=back

=over 4

=item recv example #2

  # given: synopsis

  $registry->send($process);

  $registry->recv($process);

=back

=cut

=head2 send

  send(Process $proc) : Str

The send method commits the process metadata to the registry overwriting any
existing data.

=over 4

=item send example #1

  # given: synopsis

  $registry->send($process);

=back

=over 4

=item send example #2

  # given: synopsis

  $registry->drop;

  $registry->send($process);

=back

=cut

=head2 term

  term(Str @keys) : Str

The term method generates a term (safe string) for the registry.

=over 4

=item term example #1

  # given: synopsis

  $registry->term($process->name);

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
