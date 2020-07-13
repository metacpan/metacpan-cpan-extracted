package Zing::Zang::Timer;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

extends 'Zing::Timer';

our $VERSION = '0.13'; # VERSION

# ATTRIBUTES

has 'on_perform' => (
  is => 'ro',
  isa => 'Maybe[CodeRef]',
  opt => 1,
);

has 'on_receive' => (
  is => 'ro',
  isa => 'Maybe[CodeRef]',
  opt => 1,
);

has 'schedules' => (
  is => 'ro',
  isa => 'ArrayRef[Schedule]',
  req => 1,
);

1;
=encoding utf8

=head1 NAME

Zing::Zang::Timer - Timer Process

=cut

=head1 ABSTRACT

Timer Process Implementation

=cut

=head1 SYNOPSIS

  use Zing::Zang::Timer;

  my $zang = Zing::Zang::Timer->new(
    schedules => [['@minute', ['tasks'], {do => 1}]],
  );

  # $zang->execute;

=cut

=head1 DESCRIPTION

This package provides a L<Zing::Timer> which uses callbacks and doesn't need to
be subclassd. It supports providing a process C<perform> method as
C<on_perform> and a C<receive> method as C<on_receive> which operate as
expected, and also a C<schedules> attribute which takes a list of schedules to
enforce.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Zing::Timer>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Zing::Types>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 on_perform

  on_perform(Maybe[CodeRef])

This attribute is read-only, accepts C<(Maybe[CodeRef])> values, and is optional.

=cut

=head2 on_receive

  on_receive(Maybe[CodeRef])

This attribute is read-only, accepts C<(Maybe[CodeRef])> values, and is optional.

=cut

=head2 schedules

  schedules(ArrayRef[Schedule])

This attribute is read-only, accepts C<(ArrayRef[Schedule])> values, and is required.

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
