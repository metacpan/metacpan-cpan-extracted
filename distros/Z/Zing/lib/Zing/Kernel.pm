package Zing::Kernel;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

extends 'Zing::Watcher';

use Zing::Logic::Kernel;

our $VERSION = '0.25'; # VERSION

# ATTRIBUTES

has 'journal' => (
  is => 'ro',
  isa => 'Channel',
  new => 1,
);

fun new_journal($self) {
  $self->app->journal
}

has 'scheme' => (
  is => 'ro',
  isa => 'Scheme',
  req => 1,
);

# BUILDERS

fun new_logic($self) {
  my $debug = $self->env->debug;
  Zing::Logic::Kernel->new(debug => $debug, process => $self)
}

# METHODS

method term() {
  return $self->app->term($self)->kernel;
}

1;

=encoding utf8

=head1 NAME

Zing::Kernel - Kernel Process

=cut

=head1 ABSTRACT

Kernel Watcher Process

=cut

=head1 SYNOPSIS

  use Zing::Kernel;

  my $kernel = Zing::Kernel->new(scheme => ['MyApp', [], 1]);

  # $kernel->execute;

=cut

=head1 DESCRIPTION

This package provides a watcher process which launches the scheme and
supervises the resulting process, and thus is a system manager with control
over everything in the system.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Zing::Watcher>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Zing::Types>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 journal

  journal(Channel)

This attribute is read-only, accepts C<(Channel)> values, and is optional.

=cut

=head2 scheme

  scheme(Scheme)

This attribute is read-only, accepts C<(Scheme)> values, and is required.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 execute

  execute() : Object

The execute method launches the scheme and executes the event-loops for all
processes.

=over 4

=item execute example #1

  # given: synopsis

  $kernel->execute;

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
