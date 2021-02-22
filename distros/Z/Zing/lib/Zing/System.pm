package Zing::System;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

extends 'Zing::Process';

our $VERSION = '0.27'; # VERSION

# ATTRIBUTES

has command => (
  is => 'ro',
  isa => 'ArrayRef[Str]',
  req => 1,
);

# METHODS

method perform(Any @args) {
  return exec(@{$self->command});
}

1;



=encoding utf8

=head1 NAME

Zing::System - System Command Process

=cut

=head1 ABSTRACT

System Command Process Abstraction

=cut

=head1 SYNOPSIS

  use Zing::System;

  my $system = Zing::System->new(
    command => ['perl -v | head -n 2 | tail -n 1'],
  );

  # $system->execute;

=cut

=head1 DESCRIPTION

This package provides an actor abstraction which executes a system command
using C<exec>.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Zing::Process>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Zing::Types>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 command

  command(ArrayRef[Str])

This attribute is read-only, accepts C<(ArrayRef[Str])> values, and is required.

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
