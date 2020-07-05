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
data: ro, opt, Str
journal: ro, opt, Str
log: ro, opt, Str
logic: ro, opt, Str
loop: ro, opt, Str
mailbox: ro, opt, Str
name: ro, opt, Str
node: ro, opt, Str
parent: ro, opt, Str
registry: ro, opt, Str
server: ro, opt, Str
signals: ro, opt, Str
started: ro, opt, Str
stopped: ro, opt, Str

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

=method ping

The ping method returns truthy if the process of the PID provided is active.

=signature ping

ping(Int $pid) : Bool

=example-1 ping

  # given: synopsis

  $process->ping(12345);

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
  my $global = qr/zing:main:global/;
  my $local = qr/zing:main:local\(\d+\.\d+\.\d+\.\d+\)/;
  my $process = qr/\d+\.\d+\.\d+\.\d+:\d+:\d+:\d+/;
  like $result->{data}, qr/$local:data:$process/;
  like $result->{mailbox}, qr/$global:mailbox:$process/;
  like $result->{name}, $process;
  like $result->{node}, qr/\d+:\d+/;
  ok !$result->{parent};
  like $result->{process}, qr/\d+/;
  like $result->{server}, qr/\d+\.\d+\.\d+\.\d+/;
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
  my $local = qr/zing:main:local\(\d+\.\d+\.\d+\.\d+\)/;
  my $process = qr/\d+\.\d+\.\d+\.\d+:\d+:\d+:\d+/;
  like $result, qr/$local:process:$process/;

  $result
});

$subs->example(-1, 'winddown', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

ok 1 and done_testing;
