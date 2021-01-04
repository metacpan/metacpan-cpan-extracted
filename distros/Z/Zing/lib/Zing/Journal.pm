package Zing::Journal;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

extends 'Zing::Channel';

our $VERSION = '0.25'; # VERSION

# ATTRIBUTES

has 'name' => (
  is => 'ro',
  isa => 'Str',
  init_arg => undef,
  new => 1,
  mod => 1,
);

fun new_name($self) {
  '$journal'
}

has level => (
  is => 'ro',
  isa => 'Str',
  def => 'debug',
);

has tap => (
  is => 'rw',
  isa => 'Bool',
  def => 1,
);

has verbose => (
  is => 'ro',
  isa => 'Bool',
  def => 0,
);

# METHODS

method stream(CodeRef $callback) {
  while ($self->tap) {
    next unless my $info = $self->recv;

    my $from = $info->{from};
    my $data = $info->{data};
    my $logs = $data->{logs};

    $logs->{level} = $self->level;

    my $logger = $self->app->logger(%{$logs});
    my $report = $self->verbose ? 'verbose' : 'simple';
    my $lines = $logger->$report->lines;

    $callback->($info, $data, $lines);
  }

  return $self;
}

1;

=encoding utf8

=head1 NAME

Zing::Journal - System Journal

=cut

=head1 ABSTRACT

Central System Journal

=cut

=head1 SYNOPSIS

  use Zing::Journal;

  my $journal = Zing::Journal->new;

  # $journal->recv;

=cut

=head1 DESCRIPTION

This package provides the default central mechanism for creating and retrieving
process event logs.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Zing::Channel>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Zing::Types>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 level

  level(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 name

  name(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 tap

  tap(Bool)

This attribute is read-write, accepts C<(Bool)> values, and is optional.

=cut

=head2 verbose

  verbose(Bool)

This attribute is read-only, accepts C<(Bool)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 stream

  stream(CodeRef $callback) : Object

The stream method taps the process event log and executes the provided callback
for each new event.

=over 4

=item stream example #1

  # given: synopsis

  my $example = {
    from => '...',
    data => {logs => {}},
  };

  for (1..5) {
    $journal->send($example);
  }

  $journal->stream(sub {
    my ($info, $data, $lines) = @_;
    $journal->tap(0); # stop
  });

=back

=cut

=head2 term

  term() : Str

The term method returns the name of the journal.

=over 4

=item term example #1

  # given: synopsis

  $journal->term;

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
