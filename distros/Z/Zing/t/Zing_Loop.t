use 5.014;

use strict;
use warnings;
use routines;

use lib 't/app';
use lib 't/lib';

use Test::Auto;
use Test::More;
use Test::Trap;
use Test::Zing;

=name

Zing::Loop

=cut

=tagline

Event Loop

=abstract

Process Event Loop

=cut

=includes

method: execute
method: exercise

=cut

=synopsis

  use Zing::Flow;
  use Zing::Loop;

  my $loop = Zing::Loop->new(
    flow => Zing::Flow->new(name => 'init', code => sub {1})
  );

=cut

=libraries

Zing::Types

=cut

=attributes

flow: ro, req, Flow
last: ro, opt, Bool
stop: ro, opt, Bool

=cut

=description

This package provides represents the process event-loop, it is implemented as
an infinite loop which executes L<Zing::Flow> objects.

=cut

=method execute

The execute method executes the event-loop indefinitely.

=signature execute

execute(Any @args) : Object

=example-1 execute

  # given: synopsis

  $loop->execute;

=cut

=method exercise

The exercise method executes the event-loop and stops after the first cycle.

=signature exercise

exercise(Any @args) : Object

=example-1 exercise

  # given: synopsis

  $loop->exercise;

=example-2 exercise

  package Loop;

  our $i = 0;

  my $flow_0 = Zing::Flow->new(
    name => 'flow_0',
    code => sub {
      my ($flow, $loop) = @_; $loop->stop(1);
    }
  );
  my $flow_1 = $flow_0->next(Zing::Flow->new(
    name => 'flow_1',
    code => sub {
      my ($flow, $loop) = @_; $i++;
    }
  ));

  my $loop = Zing::Loop->new(flow => $flow_0);

  $loop->exercise;

=example-3 exercise

  package Loop;

  our $i = 0;

  my $flow_0 = Zing::Flow->new(
    name => 'flow_0',
    code => sub {
      my ($flow, $loop) = @_; $loop->last(1);
    }
  );
  my $flow_1 = $flow_0->next(Zing::Flow->new(
    name => 'flow_1',
    code => sub {
      my ($flow, $loop) = @_; $i++;
    }
  ));

  my $loop = Zing::Loop->new(flow => $flow_0);

  $loop->exercise;

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'execute', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'exercise', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-2, 'exercise', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $Loop::i, 0;

  $result
});

$subs->example(-3, 'exercise', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $Loop::i, 1;

  $result
});

ok 1 and done_testing;
