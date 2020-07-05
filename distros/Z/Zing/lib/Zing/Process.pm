package Zing::Process;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

use FlightRecorder;
use POSIX;

use Zing::Channel;
use Zing::Data;
use Zing::Fork;
use Zing::Logic;
use Zing::Loop;
use Zing::Mailbox;
use Zing::Node;
use Zing::Registry;
use Zing::Term;

our $VERSION = '0.10'; # VERSION

# ATTRIBUTES

has 'cleanup' => (
  is => 'ro',
  isa => 'Bool',
  def => 1,
);

has 'data' => (
  is => 'ro',
  isa => 'Data',
  new => 1,
);

fun new_data($self) {
  Zing::Data->new(process => $self)
}

has 'journal' => (
  is => 'ro',
  isa => 'Channel',
  new => 1,
);

fun new_journal($self) {
  Zing::Channel->new(name => '$journal')
}

has 'log' => (
  is => 'ro',
  isa => 'Logger',
  new => 1,
);

fun new_log($self) {
  FlightRecorder->new(auto => undef, level => 'info')
}

has 'logic' => (
  is => 'ro',
  isa => 'Logic',
  new => 1,
);

fun new_logic($self) {
  Zing::Logic->new(process => $self);
}

has 'loop' => (
  is => 'ro',
  isa => 'Loop',
  new => 1,
);

fun new_loop($self) {
  Zing::Loop->new(flow => $self->logic->flow)
}

has 'mailbox' => (
  is => 'ro',
  isa => 'Mailbox',
  new => 1,
);

fun new_mailbox($self) {
  Zing::Mailbox->new(process => $self)
}

has 'name' => (
  is => 'ro',
  isa => 'Str',
  new => 1,
);

fun new_name($self) {
  $self->node->identifier
}

has 'node' => (
  is => 'ro',
  isa => 'Node',
  new => 1,
);

fun new_node($self) {
  Zing::Node->new
}

has 'parent' => (
  is => 'ro',
  isa => 'Maybe[Process]',
  opt => 1,
);

has 'registry' => (
  is => 'ro',
  isa => 'Registry',
  new => 1,
);

fun new_registry($self) {
  Zing::Registry->new
}

has 'server' => (
  is => 'ro',
  isa => 'Server',
  new => 1,
);

fun new_server($self) {
  Zing::Server->new
}

has 'signals' => (
  is => 'ro',
  isa => 'Map[Interupt, Str|CodeRef]',
  new => 1,
);

fun new_signals($self) {
  $self->logic->signals
}

has 'started' => (
  is => 'rw',
  isa => 'Int',
  def => 0,
);

has 'stopped' => (
  is => 'rw',
  isa => 'Int',
  def => 0,
);

has 'tag' => (
  is => 'rw',
  isa => 'Str',
  opt => 1,
);

# SHIMS

sub _kill {
  CORE::kill(shift, shift)
}

# METHODS

method defer(HashRef $data) {
  $self->mailbox->send($self->mailbox->term, $data);

  return $self;
}

method destroy() {
  return $self if !$self->cleanup;

  $self->data->drop;
  $self->mailbox->drop;
  $self->registry->drop($self);

  return $self;
}

method exercise() {
  $self->started(time);

  my $signals = $self->signals;

  local $SIG{CHLD} = $signals->{CHLD} if $signals->{CHLD};
  local $SIG{HUP}  = $signals->{HUP}  if $signals->{HUP};
  local $SIG{INT}  = $signals->{INT}  if $signals->{INT};
  local $SIG{QUIT} = $signals->{QUIT} if $signals->{QUIT};
  local $SIG{TERM} = $signals->{TERM} if $signals->{TERM};
  local $SIG{USR1} = $signals->{USR1} if $signals->{USR1};
  local $SIG{USR2} = $signals->{USR2} if $signals->{USR2};

  $self->loop->exercise($self);

  $self->destroy;

  $self->stopped(time);

  return $self;
}

method execute() {
  $self->started(time);

  my $signals = $self->signals;

  local $SIG{CHLD} = $signals->{CHLD} if $signals->{CHLD};
  local $SIG{HUP}  = $signals->{HUP}  if $signals->{HUP};
  local $SIG{INT}  = $signals->{INT}  if $signals->{INT};
  local $SIG{QUIT} = $signals->{QUIT} if $signals->{QUIT};
  local $SIG{TERM} = $signals->{TERM} if $signals->{TERM};
  local $SIG{USR1} = $signals->{USR1} if $signals->{USR1};
  local $SIG{USR2} = $signals->{USR2} if $signals->{USR2};

  $self->loop->execute($self);

  $self->destroy;

  $self->stopped(time);

  return $self;
}

method metadata() {
  {
    name => $self->name,
    data => $self->data->term,
    mailbox => $self->mailbox->term,
    node => $self->node->name,
    parent => ($self->parent ? $self->parent->node->pid : undef),
    process => $self->node->pid,
    server => $self->server->name,
    tag => $self->tag,
  }
}

method ping(Int $pid) {
  return _kill 0, $pid;
}

method shutdown() {
  $self->loop->stop(1);

  return $self;
}

method signal(Int $pid, Str $type = 'kill') {
  return _kill uc($type), $pid;
}

method spawn(Scheme $scheme) {
  my $size = $scheme->[2];
  my $fork = Zing::Fork->new(parent => $self, scheme => $scheme);

  $SIG{CHLD} = 'IGNORE';

  $fork->execute for 1..($size || 1);

  return $fork;
}

method term() {
  return Zing::Term->new($self)->process;
}

method winddown() {
  $self->loop->last(1);

  return $self;
}

1;

=encoding utf8

=head1 NAME

Zing::Process - Processing Unit

=cut

=head1 ABSTRACT

Processing Unit and Actor Abstraction

=cut

=head1 SYNOPSIS

  use Zing::Process;

  my $process = Zing::Process->new;

  # $process->execute;

=cut

=head1 DESCRIPTION

This package provides an actor abstraction which serve as a cooperative
concurrent computational unit in an actor-model architecture.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Zing::Types>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 cleanup

  cleanup(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 data

  data(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 journal

  journal(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 log

  log(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 logic

  logic(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 loop

  loop(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 mailbox

  mailbox(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 name

  name(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 node

  node(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 parent

  parent(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 registry

  registry(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 server

  server(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 signals

  signals(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 started

  started(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 stopped

  stopped(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 defer

  defer(HashRef $data) : Object

The defer method allows a process to sends a message to itself for later
processing.

=over 4

=item defer example #1

  # given: synopsis

  $process->defer({ task => { launch => time } });

=back

=cut

=head2 destroy

  destroy() : Object

The destroy method de-registers the process and drops the process-specific data
stores.

=over 4

=item destroy example #1

  # given: synopsis

  $process->destroy;

=back

=cut

=head2 execute

  execute() : Object

The execute method executes the process event-loop indefinitely.

=over 4

=item execute example #1

  # given: synopsis

  $process->execute;

=back

=cut

=head2 exercise

  exercise() : Object

The exercise method executes the event-loop but stops after one iteration.

=over 4

=item exercise example #1

  # given: synopsis

  $process->exercise;

=back

=cut

=head2 metadata

  metadata() : HashRef

The metadata method returns metadata specific to the process.

=over 4

=item metadata example #1

  # given: synopsis

  $process->metadata;

=back

=cut

=head2 ping

  ping(Int $pid) : Bool

The ping method returns truthy if the process of the PID provided is active.

=over 4

=item ping example #1

  # given: synopsis

  $process->ping(12345);

=back

=cut

=head2 shutdown

  shutdown() : Object

The shutdown method haults the process event-loop immediately.

=over 4

=item shutdown example #1

  # given: synopsis

  $process->shutdown;

=back

=cut

=head2 signal

  signal(Int $pid, Str $type = 'kill') : Int

The signal method sends a C<kill> signal to the process of the PID provided.

=over 4

=item signal example #1

  # given: synopsis

  $process->signal(12345);

=back

=over 4

=item signal example #2

  # given: synopsis

  $process->signal(12345, 'term');

=back

=cut

=head2 spawn

  spawn(Scheme $scheme) : Fork

The spawn method forks a scheme and returns a L<Zing::Fork> handler.

=over 4

=item spawn example #1

  # given: synopsis

  $process->spawn(['MyApp', [], 1]);

=back

=cut

=head2 term

  term() : Str

The term method generates a term (safe string) for the datastore.

=over 4

=item term example #1

  # given: synopsis

  $process->term;

=back

=cut

=head2 winddown

  winddown() : Object

The winddown method haults the process event-loop after the current iteration.

=over 4

=item winddown example #1

  # given: synopsis

  $process->winddown;

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
