package Zing::Logic::Single;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;

extends 'Zing::Logic';

our $VERSION = '0.21'; # VERSION

# METHODS

method flow() {
  my $step_0 = Zing::Flow->new(
    name => 'on_register',
    code => fun($step, $loop) { $self->trace('on_register')->($self) }
  );
  my $step_1 = $step_0->next(Zing::Flow->new(
    name => 'on_perform',
    code => fun($step, $loop) { $self->trace('on_perform')->($self) }
  ));
  my $step_2 = $step_1->next(Zing::Flow->new(
    name => 'on_reset',
    code => fun($step, $loop) { $self->trace('on_reset')->($self) }
  ));
  my $step_3 = $step_2->next(Zing::Flow->new(
    name => 'on_suicide',
    code => fun($step, $loop) { $self->trace('on_suicide')->($self) }
  ));

  $step_0
}

method handle_perform_event() {
  my $process = $self->process;

  my $result = $self->next::method;

  $process->winddown;

  return $result;
}

1;

=encoding utf8

=head1 NAME

Zing::Logic::Single - Single Logic

=cut

=head1 ABSTRACT

Single Process Logic Chain

=cut

=head1 SYNOPSIS

  package Single;

  use parent 'Zing::Single';

  package main;

  use Zing::Logic::Single;

  my $logic = Zing::Logic::Single->new(process => Single->new);

  # $logic->execute;

=cut

=head1 DESCRIPTION

This package provides the logic (or logic chain) to be executed by the process
event-loop.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Zing::Logic>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Zing::Types>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 interupt

  interupt(Interupt)

This attribute is read-only, accepts C<(Interupt)> values, and is optional.

=cut

=head2 on_perform

  on_perform(CodeRef)

This attribute is read-only, accepts C<(CodeRef)> values, and is optional.

=cut

=head2 on_receive

  on_receive(CodeRef)

This attribute is read-only, accepts C<(CodeRef)> values, and is optional.

=cut

=head2 on_register

  on_register(CodeRef)

This attribute is read-only, accepts C<(CodeRef)> values, and is optional.

=cut

=head2 on_reset

  on_reset(CodeRef)

This attribute is read-only, accepts C<(CodeRef)> values, and is optional.

=cut

=head2 on_suicide

  on_suicide(CodeRef)

This attribute is read-only, accepts C<(CodeRef)> values, and is optional.

=cut

=head2 process

  process(Process)

This attribute is read-only, accepts C<(Process)> values, and is required.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 flow

  flow() : Flow

The flow method builds and returns the logic flow for the process event-loop.

=over 4

=item flow example #1

  # given: synopsis

  my $flow = $logic->flow;

=back

=cut

=head2 signals

  signals() : HashRef

The signals method builds and returns the process signal handlers.

=over 4

=item signals example #1

  # given: synopsis

  my $signals = $logic->signals;

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
