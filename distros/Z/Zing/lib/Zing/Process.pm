package Zing::Process;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

extends 'Zing::Entity';

use FlightRecorder;
use POSIX;

use Zing::Logic;
use Zing::Loop;

our $VERSION = '0.27'; # VERSION

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
  $self->app->data(name => $self->name)
}

has 'journal' => (
  is => 'ro',
  isa => 'Channel',
  new => 1,
);

fun new_journal($self) {
  $self->app->journal
}

has 'log' => (
  is => 'ro',
  isa => 'Logger',
  new => 1,
);

fun new_log($self) {
  $self->app->logger(auto => undef)
}

has 'logic' => (
  is => 'ro',
  isa => 'Logic',
  new => 1,
);

fun new_logic($self) {
  my $debug = $self->env->debug;
  Zing::Logic->new(debug => $debug, process => $self)
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
  $self->app->mailbox(name => $self->name)
}

has 'meta' => (
  is => 'ro',
  isa => 'Meta',
  new => 1,
);

fun new_meta($self) {
  $self->app->meta(name => $self->name)
}

has 'name' => (
  is => 'ro',
  isa => 'Name',
  new => 1,
);

fun new_name($self) {
  $self->app->id->string
}

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

has 'parent' => (
  is => 'ro',
  isa => 'Maybe[Process]',
  opt => 1,
);

has 'pid' => (
  is => 'ro',
  isa => 'Int',
  new => 1,
);

fun new_pid($self) {
  $self->app->pid
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
  $self->meta->drop;

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
    host => $self->app->host,
    mailbox => $self->mailbox->term,
    parent => ($self->parent ? $self->parent->pid : undef),
    process => $self->pid,
    tag => $self->tag,
  }
}

method perform(@args) {
  return $self if !$self->on_perform;

  my $performed = $self->on_perform->($self, @args);

  return $performed;
}

method receive(@args) {
  return $self if !$self->on_receive;

  my $received = $self->on_receive->($self, @args);

  return $received;
}

method recv() {
  return $self->mailbox->recv;
}

method reply(HashRef $mail, HashRef $data) {
  return $self->mailbox->send($mail->{from}, $data);
}

method send(Mailbox | Process | Str $to, HashRef $data) {
  if (!ref $to) {
    return $self->mailbox->send($self->app->term($to)->mailbox, $data);
  }
  elsif ($to->isa('Zing::Mailbox')) {
    return $self->mailbox->send($to->term, $data);
  }
  elsif ($to->isa('Zing::Process')) {
    return $self->mailbox->send($to->mailbox->term, $data);
  }
  else {
    return $self->mailbox->send($self->app->term($to)->mailbox, $data);
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
  my $fork = $self->app->fork(parent => $self, scheme => $scheme);

  $SIG{CHLD} = 'IGNORE';

  $fork->execute for 1..($size || 1);

  return $fork;
}

method term() {
  return $self->app->term($self)->process;
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

  data(Data)

This attribute is read-only, accepts C<(Data)> values, and is optional.

=cut

=head2 journal

  journal(Channel)

This attribute is read-only, accepts C<(Channel)> values, and is optional.

=cut

=head2 log

  log(Logger)

This attribute is read-only, accepts C<(Logger)> values, and is optional.

=cut

=head2 logic

  logic(Logic)

This attribute is read-only, accepts C<(Logic)> values, and is optional.

=cut

=head2 loop

  loop(Loop)

This attribute is read-only, accepts C<(Loop)> values, and is optional.

=cut

=head2 mailbox

  mailbox(Mailbox)

This attribute is read-only, accepts C<(Mailbox)> values, and is optional.

=cut

=head2 meta

  meta(Meta)

This attribute is read-only, accepts C<(Meta)> values, and is optional.

=cut

=head2 name

  name(Name)

This attribute is read-only, accepts C<(Name)> values, and is optional.

=cut

=head2 on_perform

  on_perform(Maybe[CodeRef])

This attribute is read-only, accepts C<(Maybe[CodeRef])> values, and is optional.

=cut

=head2 on_receive

  on_receive(Maybe[CodeRef])

This attribute is read-only, accepts C<(Maybe[CodeRef])> values, and is optional.

=cut

=head2 parent

  parent(Maybe[Process])

This attribute is read-only, accepts C<(Maybe[Process])> values, and is optional.

=cut

=head2 pid

  pid(Int)

This attribute is read-only, accepts C<(Int)> values, and is optional.

=cut

=head2 signals

  signals(HashRef[Str|CodeRef])

This attribute is read-only, accepts C<(HashRef[Str|CodeRef])> values, and is optional.

=cut

=head2 started

  started(Int)

This attribute is read-only, accepts C<(Int)> values, and is optional.

=cut

=head2 stopped

  stopped(Int)

This attribute is read-only, accepts C<(Int)> values, and is optional.

=cut

=head2 tag

  tag(Str)

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

=head2 receive

  receive(Str $from, HashRef $data) : Any

The receive method, when not overloaded, executes the callback in the
L</on_receive> attribute for each cycle of the event loop.

=over 4

=item receive example #1

  # given: synopsis

  $process = Zing::Process->new(
    on_receive => sub {
      my ($self, $from, $data) = @_;
      [$from, $data];
    },
  );

  $process->receive($process->term, { ping => 1 });

=back

=cut

=head2 recv

  recv() : Maybe[HashRef]

The recv method is a proxy for L<Zing::Mailbox/recv> and receives a single new
message from the mailbox.

=over 4

=item recv example #1

  # given: synopsis

  $process->recv;

=back

=over 4

=item recv example #2

  # given: synopsis

  my $peer = Zing::Process->new;

  $peer->send($process, { note => 'ehlo' });

  $process->recv;

=back

=cut

=head2 reply

  reply(HashRef $bag, HashRef $value) : Int

The reply method is a proxy for L<Zing::Mailbox/reply> and sends a message to
the mailbox represented by the C<$bag> received.

=over 4

=item reply example #1

  # given: synopsis

  my $peer = Zing::Process->new;

  $peer->send($process, { note => 'ehlo' });

  my $mail = $process->recv;

  $process->reply($mail, { note => 'helo' });

=back

=cut

=head2 send

  send(Mailbox | Process | Str $to, HashRef $data) : Int

The send method is a proxy for L<Zing::Mailbox/send> and sends a new message to
the mailbox specified.

=over 4

=item send example #1

  # given: synopsis

  my $peer = Zing::Process->new;

  $process->send($peer, { note => 'invite' });

=back

=over 4

=item send example #2

  # given: synopsis

  my $peer = Zing::Process->new;

  $process->send($peer->mailbox, { note => 'invite' });

=back

=over 4

=item send example #3

  # given: synopsis

  my $peer = Zing::Process->new;

  $process->send($peer->mailbox->term, { note => 'invite' });

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
file"|https://github.com/cpanery/zing/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/cpanery/zing/wiki>

L<Project|https://github.com/cpanery/zing>

L<Initiatives|https://github.com/cpanery/zing/projects>

L<Milestones|https://github.com/cpanery/zing/milestones>

L<Contributing|https://github.com/cpanery/zing/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/cpanery/zing/issues>

=cut
