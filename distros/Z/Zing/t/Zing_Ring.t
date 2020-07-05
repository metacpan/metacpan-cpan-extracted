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

Zing::Ring

=cut

=tagline

Process Ring

=cut

=abstract

Multi-Process Assembly Ring

=cut

=includes

method: perform
method: destroy
method: shutdown
method: winddown

=cut

=synopsis

  use Zing::Ring;
  use Zing::Process;

  my $ring = Zing::Ring->new(processes => [
    Zing::Process->new,
    Zing::Process->new,
  ]);

  # $ring->execute;

=cut

=libraries

Zing::Types

=cut

=inherits

Zing::Process

=cut

=attributes

processes: ro, req, ArrayRef[Process]

=cut

=description

This package provides a mechanism for joining two (or more) processes and
executes them as one in a turn-based manner.

=cut

=method perform

The perform method executes the event-loop of the next process in the list with
each call.

=signature perform

perform() : Any

=example-1 perform

  # given: synopsis

  [$ring, $ring->perform]

=cut

=method destroy

The destroy method executes the C<destroy> method of all the processes in the
list.

=signature destroy

destroy() : Object

=example-1 destroy

  # given: synopsis

  [$ring, $ring->destroy]

=cut

=method shutdown

The shutdown method executes the C<shutdown> method of all the processes in the
list.

=signature shutdown

shutdown() : Object

=example-1 shutdown

  # given: synopsis

  [$ring, $ring->shutdown]

=cut

=method winddown

The winddown method executes the C<winddown> method of all the processes in the
list.

=signature winddown

winddown() : Object

=example-1 winddown

  # given: synopsis

  [$ring, $ring->winddown]

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'perform', 'method', fun($tryable) {
  my ($ring, $result) = @{$tryable->result};

  ok $ring;
  ok $result;

  ok !$ring->processes->[0]->started;
  ok !$ring->processes->[1]->started;

  ok !$ring->processes->[0]->stopped;
  ok !$ring->processes->[1]->stopped;

  $ring->execute;

  ok $ring->processes->[0]->started;
  ok $ring->processes->[0]->stopped;

  ok $ring->processes->[1]->started;
  ok $ring->processes->[1]->stopped;

  $result
});

$subs->example(-1, 'destroy', 'method', fun($tryable) {
  my ($ring, $result) = @{$tryable->result};

  ok $ring;
  ok $result;

  $result
});

$subs->example(-1, 'shutdown', 'method', fun($tryable) {
  my ($ring, $result) = @{$tryable->result};

  ok $ring;
  ok $result;

  ok !$ring->processes->[0]->loop->last;
  ok !$ring->processes->[1]->loop->last;

  ok $ring->processes->[0]->loop->stop;
  ok $ring->processes->[1]->loop->stop;

  $result
});

$subs->example(-1, 'winddown', 'method', fun($tryable) {
  my ($ring, $result) = @{$tryable->result};

  ok $ring;
  ok $result;

  ok $ring->processes->[0]->loop->last;
  ok $ring->processes->[1]->loop->last;

  ok !$ring->processes->[0]->loop->stop;
  ok !$ring->processes->[1]->loop->stop;

  $result
});

ok 1 and done_testing;
