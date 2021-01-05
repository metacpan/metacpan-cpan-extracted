package Zing::Single;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;

use Zing::Logic::Single;

extends 'Zing::Process';

our $VERSION = '0.26'; # VERSION

# BUILDERS

fun new_logic($self) {
  my $debug = $self->env->debug;
  Zing::Logic::Single->new(debug => $debug, process => $self)
}

1;

=encoding utf8

=head1 NAME

Zing::Single - Single Process

=cut

=head1 ABSTRACT

Single Process

=cut

=head1 SYNOPSIS

  package MyApp;

  use parent 'Zing::Single';

  sub perform {
    my ($self) = @_;

    time;
  }

  sub receive {
    my ($self, $from, $data) = @_;

    [$from, $data];
  }

  package main;

  my $myapp = MyApp->new;

  # $myapp->execute;

=cut

=head1 DESCRIPTION

This package provides a L<Zing::Process> which runs once and shuts-down, but
otherwise operates as a typical process and invokes its C<receive> and
C<perform> methods.

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

  $myapp->receive($myapp->name, { task => 'fuzzy_logic' });

The receive method is meant to be implemented by a subclass and is
automatically invoked iteratively by the event-loop whenever a process receives
a message in its mailbox.

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
