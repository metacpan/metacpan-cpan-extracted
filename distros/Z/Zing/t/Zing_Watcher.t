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

Zing::Watcher

=cut

=tagline

Watcher Process

=abstract

Watcher Process

=cut

=includes

method: scheme

=cut

=synopsis

  package MyApp;

  use parent 'Zing::Watcher';

  sub perform {
    time;
  }

  sub receive {
    my ($self, $from, $data) = @_;

    [$from, $data];
  }

  sub scheme {
    ['MyApp::Handler', [], 1];
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

on_scheme: ro, opt, Maybe[CodeRef]

=cut

=description

This package provides a L<Zing::Process> which forks a C<scheme> using
L<Zong::Fork> and maintains the desired active processes. The standard process
C<perform> and C<receive> methods operate as expected.

=cut

=scenario perform

The perform method is meant to be implemented by a subclass and is
automatically invoked iteratively by the event-loop.

=example perform

  # given: synopsis

  $myapp->perform;

=scenario receive

The receive method is meant to be implemented by a subclass and is
automatically invoked iteratively by the event-loop.

=example receive

  # given: synopsis

  $myapp->receive($myapp->name, { status => 'ok' });

=scenario scheme

The scheme method is meant to be implemented by a subclass and is
automatically invoked when the process is executed.

=example scheme

  # given: synopsis

  $myapp->scheme;

=method scheme

The scheme method, when not overloaded, executes the callback in the
L</on_scheme> attribute and expects a process scheme to be processed.

=signature scheme

scheme(Any @args) : Scheme

=example-1 scheme

  my $watcher = Zing::Watcher->new(
    on_scheme => sub {
      ['MyApp::Handler', [], 1]
    },
  );

  $watcher->scheme;

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('MyApp');
  ok $result->isa('Zing::Watcher');

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

$subs->scenario('scheme', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'scheme', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['MyApp::Handler', [], 1];

  $result
});

ok 1 and done_testing;
