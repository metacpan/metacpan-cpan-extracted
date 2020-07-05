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

Zing::Launcher

=cut

=tagline

Scheme Launcher

=abstract

Scheme Launching Worker Process

=cut

=includes

method: handle

=cut

=synopsis

  package Launcher;

  use parent 'Zing::Launcher';

  sub queues {
    ['schemes']
  }

  package main;

  my $launcher = Launcher->new;

  # $launcher->execute;

=cut

=libraries

Zing::Types

=cut

=inherits

Zing::Worker

=cut

=description

This package provides a worker process which loads, instantiates, and executes
schemes received as messages.

=cut

=method handle

The handle method is executed whenever the process receive a new message, and
receives the queue name and data as arguments.

=signature handle

handle(Str $name, HashRef $data) : Object

=example-1 handle

  # given: synopsis

  $launcher->handle('schemes', { scheme => ['MyApp', [], 1] });

=example-2 handle

  # given: synopsis

  $launcher->handle('schemes', { scheme => ['MyApp', [], 4] });

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

$subs->example(-1, 'handle', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $MyApp::DATA, 1;

  $MyApp::DATA = 0;

  $result
});

$subs->example(-2, 'handle', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $MyApp::DATA, 4;

  $MyApp::DATA = 0;

  $result
});

ok 1 and done_testing;
