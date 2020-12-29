package Zing::Scheduler;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;

extends 'Zing::Launcher';

our $VERSION = '0.22'; # VERSION

# METHODS

method queues() {
  ['$scheduled']
}

1;

=encoding utf8

=head1 NAME

Zing::Scheduler - Scheme Launcher

=cut

=head1 ABSTRACT

Default Scheme Launcher

=cut

=head1 SYNOPSIS

  use Zing::Scheduler;

  my $scheduler = Zing::Scheduler->new;

  # $scheduler->execute;

=cut

=head1 DESCRIPTION

This package provides a local (node-specific, not cluster-wide) launcher
process which is a type of worker process which loads, instantiates, and
executes L<"schemes"|Zing::Types/scheme>.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Zing::Launcher>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Zing::Types>

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 queues

  queues() : ArrayRef[Str]

The queues method executes something which triggers something else.

=over 4

=item queues example #1

  # given: synopsis

  my $queues = $scheduler->queues;

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
