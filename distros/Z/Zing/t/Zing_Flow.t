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

Zing::Flow

=cut

=tagline

Loop Step

=abstract

Event-Loop Logic Chain

=cut

=includes

method: append
method: bottom
method: execute
method: prepend

=cut

=synopsis

  use Zing::Flow;

  my $flow = Zing::Flow->new(name => 'step_1', code => sub {1});

  # $flow->execute;

=cut

=libraries

Zing::Types

=cut

=attributes

name: ro, req, Str
next: rw, opt, Flow
code: ro, req, CodeRef

=cut

=description

This package provides represents an event-loop step, it is implemented as a
simplified linked-list that allows other flows to be appended, prepended, and
injected easily, anywhere in the flow.

=cut

=method append

The append method appends the flow provided to the end of its chain.

=signature append

append(Flow $flow) : Flow

=example-1 append

  # given: synopsis

  my $next = Zing::Flow->new(name => 'step_2', code => sub {2});

  $flow->append($next);

=cut

=method bottom

The bottom method returns the flow object at the end of its chain.

=signature bottom

bottom() : Flow

=example-1 bottom

  # given: synopsis

  $flow->bottom;

=example-2 bottom

  # given: synopsis

  my $next = Zing::Flow->new(name => 'step_2', code => sub {2});

  $flow->next($next);

  $flow->bottom;

=cut

=method execute

The execute method executes its code routine as a method call.

=signature execute

execute(Any @args) : Any

=example-1 execute

  # given: synopsis

  $flow->execute;

=cut

=method prepend

The prepend method prepends the flow provided by adding itself to the end of
that chain and returns the flow object provided.

=signature prepend

prepend(Flow $flow) : Flow

=example-1 prepend

  # given: synopsis

  my $base = Zing::Flow->new(name => 'step_0', code => sub {0});

  $flow->prepend($base);

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'append', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result->name, 'step_1';

  $result
});

$subs->example(-1, 'bottom', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result->name, 'step_1';

  $result
});

$subs->example(-2, 'bottom', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result->name, 'step_2';

  $result
});

$subs->example(-1, 'execute', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 1;

  $result
});

$subs->example(-1, 'prepend', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result->name, 'step_0';
  is $result->bottom->name, 'step_1';

  $result
});

ok 1 and done_testing;
