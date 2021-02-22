use 5.014;

use strict;
use warnings;
use routines;

use lib 't/app';
use lib 't/lib';

use Test::Auto;
use Test::More;
use Test::Zing;

=name

Zing::Process

=cut

=tagline

Processing Unit

=abstract

Processing Unit and Actor Abstraction

=cut

=includes

method: defer
method: destroy
method: exercise
method: execute
method: metadata
method: ping
method: receive
method: recv
method: reply
method: send
method: shutdown
method: signal
method: spawn
method: term
method: winddown

=cut

=synopsis

  use Zing::Process;

  my $process = Zing::Process->new;

  # $process->execute;

=cut

=libraries

Zing::Types

=cut

=attributes

cleanup: ro, opt, Str
data: ro, opt, Data
journal: ro, opt, Channel
log: ro, opt, Logger
logic: ro, opt, Logic
loop: ro, opt, Loop
mailbox: ro, opt, Mailbox
meta: ro, opt, Meta
name: ro, opt, Name
on_perform: ro, opt, Maybe[CodeRef]
on_receive: ro, opt, Maybe[CodeRef]
parent: ro, opt, Maybe[Process]
pid: ro, opt, Int
signals: ro, opt, HashRef[Str|CodeRef]
started: ro, opt, Int
stopped: ro, opt, Int
tag: ro, opt, Str

=cut

=description

This package provides an actor abstraction which serve as a cooperative
concurrent computational unit in an actor-model architecture.

=cut

=method defer

The defer method allows a process to sends a message to itself for later
processing.

=signature defer

defer(HashRef $data) : Object

=example-1 defer

  # given: synopsis

  $process->defer({ task => { launch => time } });

=cut

=method destroy

The destroy method de-registers the process and drops the process-specific data
stores.

=signature destroy

destroy() : Object

=example-1 destroy

  # given: synopsis

  $process->destroy;

=cut

=method exercise

The exercise method executes the event-loop but stops after one iteration.

=signature exercise

exercise() : Object

=example-1 exercise

  # given: synopsis

  $process->exercise;

=cut

=method execute

The execute method executes the process event-loop indefinitely.

=signature execute

execute() : Object

=example-1 execute

  # given: synopsis

  $process->execute;

=cut

=method metadata

The metadata method returns metadata specific to the process.

=signature metadata

metadata() : HashRef

=example-1 metadata

  # given: synopsis

  $process->metadata;

=cut

=method perform

The perform method, when not overloaded, executes the callback in the
L</on_perform> attribute for each cycle of the event loop.

=signature perform

perform() : Any

=example-1 perform

  # given: synopsis

  $process = Zing::Process->new(
    on_perform => sub {
      rand;
    },
  );

  $process->perform;

=method ping

The ping method returns truthy if the process of the PID provided is active.

=signature ping

ping(Int $pid) : Bool

=example-1 ping

  # given: synopsis

  $process->ping(12345);

=cut

=method receive

The receive method, when not overloaded, executes the callback in the
L</on_receive> attribute for each cycle of the event loop.

=signature receive

receive(Str $from, HashRef $data) : Any

=example-1 receive

  # given: synopsis

  $process = Zing::Process->new(
    on_receive => sub {
      my ($self, $from, $data) = @_;
      [$from, $data];
    },
  );

  $process->receive($process->term, { ping => 1 });

=cut

=method recv

The recv method is a proxy for L<Zing::Mailbox/recv> and receives a single new
message from the mailbox.

=signature recv

recv() : Maybe[HashRef]

=example-1 recv

  # given: synopsis

  $process->recv;

=example-2 recv

  # given: synopsis

  my $peer = Zing::Process->new;

  $peer->send($process, { note => 'ehlo' });

  $process->recv;

=cut

=method reply

The reply method is a proxy for L<Zing::Mailbox/reply> and sends a message to
the mailbox represented by the C<$bag> received.

=signature reply

reply(HashRef $bag, HashRef $value) : Int

=example-1 reply

  # given: synopsis

  my $peer = Zing::Process->new;

  $peer->send($process, { note => 'ehlo' });

  my $mail = $process->recv;

  $process->reply($mail, { note => 'helo' });

=cut

=method send

The send method is a proxy for L<Zing::Mailbox/send> and sends a new message to
the mailbox specified.

=signature send

send(Mailbox | Process | Str $to, HashRef $data) : Int

=example-1 send

  # given: synopsis

  my $peer = Zing::Process->new;

  $process->send($peer, { note => 'invite' });

=example-2 send

  # given: synopsis

  my $peer = Zing::Process->new;

  $process->send($peer->mailbox, { note => 'invite' });

=example-3 send

  # given: synopsis

  my $peer = Zing::Process->new;

  $process->send($peer->mailbox->term, { note => 'invite' });

=cut

=method shutdown

The shutdown method haults the process event-loop immediately.

=signature shutdown

shutdown() : Object

=example-1 shutdown

  # given: synopsis

  $process->shutdown;

=cut

=method signal

The signal method sends a C<kill> signal to the process of the PID provided.

=signature signal

signal(Int $pid, Str $type = 'kill') : Int

=example-1 signal

  # given: synopsis

  $process->signal(12345);

=example-2 signal

  # given: synopsis

  $process->signal(12345, 'term');

=cut

=method spawn

The spawn method forks a scheme and returns a L<Zing::Fork> handler.

=signature spawn

spawn(Scheme $scheme) : Fork

=example-1 spawn

  # given: synopsis

  $process->spawn(['MyApp', [], 1]);

=cut

=method term

The term method generates a term (safe string) for the datastore.

=signature term

term() : Str

=example-1 term

  # given: synopsis

  $process->term;

=cut

=method winddown

The winddown method haults the process event-loop after the current iteration.

=signature winddown

winddown() : Object

=example-1 winddown

  # given: synopsis

  $process->winddown;

=cut

package MyApp;

use parent 'Zing::Single';

our $DATA = 0;

sub perform {
  $DATA++
}

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'defer', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'destroy', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'exercise', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'execute', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'metadata', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  like $result->{data}, qr/zing:main:global:data:\w{40}/;
  like $result->{mailbox}, qr/zing:main:global:mailbox:\w{40}/;
  like $result->{name}, qr/\w{40}/;
  like $result->{host}, qr/.+/;
  ok !$result->{parent};
  like $result->{process}, qr/\d+/;
  ok !$result->{tag};
  $result
});

$subs->example(-1, 'ping', 'method', fun($tryable) {
  my $result;

  local $ENV{ZING_TEST_KILL} = 0;
  ok !($result = $tryable->result);

  local $ENV{ZING_TEST_KILL} = 1;
  ok $result = $tryable->result;

  $result
});

$subs->example(-1, 'receive', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is ref($result), 'ARRAY';
  is_deeply $result->[1], { ping => 1 };

  $result
});

$subs->example(-1, 'recv', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-2, 'recv', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result->{data}, { note => 'ehlo' };

  $result
});

$subs->example(-1, 'reply', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'send', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 1;

  $result
});

$subs->example(-2, 'send', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 1;

  $result
});

$subs->example(-3, 'send', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 1;

  $result
});

$subs->example(-1, 'shutdown', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'signal', 'method', fun($tryable) {
  local $ENV{ZING_TEST_KILL} = 1;
  ok my $result = $tryable->result;

  $result
});

$subs->example(-2, 'signal', 'method', fun($tryable) {
  local $ENV{ZING_TEST_KILL} = 1;
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'spawn', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'term', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  like $result, qr/zing:main:global:process:\w{40}/;

  $result
});

$subs->example(-1, 'winddown', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

ok 1 and done_testing;
