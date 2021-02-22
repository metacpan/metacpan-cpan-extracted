package Zing::Watcher;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

use Zing::Logic::Watcher;

extends 'Zing::Process';

our $VERSION = '0.27'; # VERSION

# ATTRIBUTES

has 'on_scheme' => (
  is => 'ro',
  isa => 'Maybe[CodeRef]',
  opt => 1,
);

# BUILDERS

fun new_logic($self) {
  my $debug = $self->env->debug;
  Zing::Logic::Watcher->new(debug => $debug, process => $self)
}

# METHODS

method scheme(@args) {
  return $self if !$self->on_scheme;

  my $scheme = $self->on_scheme->($self, @args);

  return $scheme;
}

1;



=encoding utf8

=head1 NAME

Zing::Watcher - Watcher Process

=cut

=head1 ABSTRACT

Watcher Process

=cut

=head1 SYNOPSIS

  package MyApp;

  use parent 'Zing::Watcher';

  sub perform {
    time;
  }

  sub receive {
    my ($self, $from, $data) = @_;

    [$from, $data];
  }

  sub scheme {
    ['MyApp::Handler', [], 1];
  }

  package main;

  my $myapp = MyApp->new;

  # $myapp->execute;

=cut

=head1 DESCRIPTION

This package provides a L<Zing::Process> which forks a C<scheme> using
L<Zong::Fork> and maintains the desired active processes. The standard process
C<perform> and C<receive> methods operate as expected.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Zing::Process>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Zing::Types>

=cut

=head1 SCENARIOS

This package supports the following scenarios:

=cut

=head2 perform

  # given: synopsis

  $myapp->perform;

The perform method is meant to be implemented by a subclass and is
automatically invoked iteratively by the event-loop.

=cut

=head2 receive

  # given: synopsis

  $myapp->receive($myapp->name, { status => 'ok' });

The receive method is meant to be implemented by a subclass and is
automatically invoked iteratively by the event-loop.

=cut

=head2 scheme

  # given: synopsis

  $myapp->scheme;

The scheme method is meant to be implemented by a subclass and is
automatically invoked when the process is executed.

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 on_scheme

  on_scheme(Maybe[CodeRef])

This attribute is read-only, accepts C<(Maybe[CodeRef])> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 scheme

  scheme(Any @args) : Scheme

The scheme method, when not overloaded, executes the callback in the
L</on_scheme> attribute and expects a process scheme to be processed.

=over 4

=item scheme example #1

  my $watcher = Zing::Watcher->new(
    on_scheme => sub {
      ['MyApp::Handler', [], 1]
    },
  );

  $watcher->scheme;

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/cpanery/zing/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/cpanery/zing/wiki>

L<Project|https://github.com/cpanery/zing>

L<Initiatives|https://github.com/cpanery/zing/projects>

L<Milestones|https://github.com/cpanery/zing/milestones>

L<Contributing|https://github.com/cpanery/zing/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/cpanery/zing/issues>

=cut
