package Zing::Ringer;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;
use Data::Object::Space;

extends 'Zing::Ring';

our $VERSION = '0.22'; # VERSION

# ATTRIBUTES

has 'processes' => (
  is => 'ro',
  isa => 'ArrayRef[Process]',
  mod => 1,
  new => 1,
  opt => 1,
);

fun new_processes($self) {
  [map $self->reify($_), @{$self->schemes}]
}

has 'schemes' => (
  is => 'ro',
  isa => 'ArrayRef[Scheme]',
  req => 1,
);

# METHODS

method reify(Scheme $scheme) {
  my $class = $scheme->[0];
  my $space = Data::Object::Space->new($class);
  my $build = $space->build(@{$scheme->[1]});

  return $build;
}

1;
=encoding utf8

=head1 NAME

Zing::Ringer - Scheme Ring

=cut

=head1 ABSTRACT

Multi-Scheme Assembly Ring

=cut

=head1 SYNOPSIS

  use Zing::Ringer;

  my $ring = Zing::Ringer->new(schemes => [
    ['MyApp', [], 1],
    ['MyApp', [], 1],
  ]);

  # $ring->execute;

=cut

=head1 DESCRIPTION

This package provides a mechanism for joining two (or more) processes from
their scheme definitions and executes them as one in a turn-based manner.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Zing::Ring>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Zing::Types>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 processes

  processes(ArrayRef[Process])

This attribute is read-only, accepts C<(ArrayRef[Process])> values, and is optional.

=cut

=head2 schemes

  schemes(ArrayRef[Scheme])

This attribute is read-only, accepts C<(ArrayRef[Scheme])> values, and is required.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 reify

  reify(Scheme $scheme) : Process

The reify method loads, instantiates, and returns a L<Zing::Process> derived
object from an application scheme.

=over 4

=item reify example #1

  # given: synopsis

  $ring->reify(['MyApp', [], 1]);

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
