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

Zing::Worker

=cut

=tagline

Worker Process

=abstract

Worker Process

=cut

=includes

method: handle
method: queues

=cut

=synopsis

  package MyApp;

  use parent 'Zing::Worker';

  sub handle {
    my ($name, $data) = @_;

    [$name, $data];
  }

  sub perform {
    time;
  }

  sub queues {
    ['todos'];
  }

  sub receive {
    my ($self, $from, $data) = @_;

    [$from, $data];
  }

  package main;

  my $myapp = MyApp->new;

  # $myapp->execute;

=cut

=libraries

Zing::Types

=cut

=inherits

Zing::Process

=cut

=attributes

on_handle: ro, opt, Maybe[CodeRef]
on_queues: ro, opt, Maybe[CodeRef]

=cut

=description

This package provides a L<Zing::Process> which listens to one or more queues
calls the C<handle> method for each new message received. The standard process
C<perform> and C<receive> methods operate as expected.

=cut

=scenario handle

The handle method is meant to be implemented by a subclass and is
automatically invoked when a message is received from a defined queue.

=example handle

  # given: synopsis

  $myapp->handle('todos', { todo => 'rebuild' });

=scenario perform

The perform method is meant to be implemented by a subclass and is
automatically invoked iteratively by the event-loop.

=example perform

  # given: synopsis

  $myapp->perform;

=scenario queues

The queues method is meant to be implemented by a subclass and is automatically
invoked when the process is executed.

=example queues

  # given: synopsis

  $myapp->queues;

=scenario receive

The receive method is meant to be implemented by a subclass and is
automatically invoked iteratively by the event-loop.

=example receive

  # given: synopsis

  $myapp->receive($myapp->name, { status => 'ok' });

=method handle

The handle method, when not overloaded, executes the callback in the
L</on_handle> attribute for each new message available in any of the queues
delcared.

=signature handle

handle(Str $queue, HashRef $data) : Any

=example-1 handle

  my $worker = Zing::Worker->new(
    on_handle => sub {
      my ($self, $queue, $data) = @_;
      [$queue, $data];
    },
  );

  $worker->handle('todos', {});

=method queues

The queues method, when not overloaded, executes the callback in the
L</on_queues> attribute and expects a list of named queues to be processed.

=signature queues

queues(Any @args) : ArrayRef[Str]

=example-1 queues

  my $worker = Zing::Worker->new(
    on_queues => sub {
      ['todos'];
    },
  );

  $worker->queues;

=example-2 queues

  my $worker = Zing::Worker->new(
    on_queues => sub {
      my ($self, @queues) = @_;
      [@queues, 'other'];
    },
  );

  $worker->queues('todos-p1', 'todos-p2', 'todos-p3');

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('MyApp');
  ok $result->isa('Zing::Worker');

  $result
});

$subs->scenario('handle', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->scenario('queues', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->scenario('perform', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->scenario('receive', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'handle', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result->[0], 'todos';
  is_deeply $result->[1], {};

  $result
});

$subs->example(-1, 'queues', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['todos'];

  $result
});

$subs->example(-2, 'queues', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['todos-p1', 'todos-p2', 'todos-p3', 'other'];

  $result
});

ok 1 and done_testing;
