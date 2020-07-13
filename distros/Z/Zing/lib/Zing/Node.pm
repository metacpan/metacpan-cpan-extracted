package Zing::Node;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

use Zing::Server;

our $VERSION = '0.13'; # VERSION

# ATTRIBUTES

my ($i, $t) = (0, time);

has 'name' => (
  is => 'ro',
  isa => 'Str',
  new => 1,
);

fun new_name($self) {
  my $name = join(':', time, sprintf('%04d', ($i = ($t == time ? $i + 1 : 1))));

  # reset iota
  $t = time;

  $name
}

has 'pid' => (
  is => 'ro',
  isa => 'Str',
  new => 1,
);

fun new_pid($self) {
  $$
}

has 'server' => (
  is => 'ro',
  isa => 'Server',
  new => 1,
);

fun new_server($self) {
  Zing::Server->new
}

# METHODS

method identifier() {

  return join ':', $self->server->name, $self->pid, $self->name;
}

1;

=encoding utf8

=head1 NAME

Zing::Node - Node Information

=cut

=head1 ABSTRACT

Process Node Information

=cut

=head1 SYNOPSIS

  use Zing::Node;

  my $node = Zing::Node->new;

=cut

=head1 DESCRIPTION

This package provides represents a process within a network and cluster.

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

=head2 pid

  pid(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 server

  server(Server)

This attribute is read-only, accepts C<(Server)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 identifier

  identifier() : Str

The identifier method generates and returns a cross-cluster unique identifier.

=over 4

=item identifier example #1

  # given: synopsis

  my $id = $node->identifier;

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
