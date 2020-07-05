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

ok 1 and done_testing;
