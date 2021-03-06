package Zing::Launcher;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::Space;

extends 'Zing::Worker';

our $VERSION = '0.27'; # VERSION

# METHODS

method handle(Str $name, HashRef $data) {
  return $self if !$data->{scheme};

  my $class = $data->{scheme}[0];
  my $space = Data::Object::Space->new($class);
  my $build = $space->build(@{$data->{scheme}[1]});

  $build->execute for 1..($data->{scheme}[2] || 1);

  return $self;
}

1;



=encoding utf8

=head1 NAME

Zing::Launcher - Scheme Launcher

=cut

=head1 ABSTRACT

Scheme Launching Worker Process

=cut

=head1 SYNOPSIS

  package Launcher;

  use parent 'Zing::Launcher';

  sub queues {
    ['schemes']
  }

  package main;

  my $launcher = Launcher->new;

  # $launcher->execute;

=cut

=head1 DESCRIPTION

This package provides a worker process which loads, instantiates, and executes
schemes received as messages.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Zing::Worker>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Zing::Types>

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 handle

  handle(Str $name, HashRef $data) : Object

The handle method is executed whenever the process receive a new message, and
receives the queue name and data as arguments.

=over 4

=item handle example #1

  # given: synopsis

  $launcher->handle('schemes', { scheme => ['MyApp', [], 1] });

=back

=over 4

=item handle example #2

  # given: synopsis

  $launcher->handle('schemes', { scheme => ['MyApp', [], 4] });

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
