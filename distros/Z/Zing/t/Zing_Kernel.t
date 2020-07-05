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

Zing::Kernel

=cut

=tagline

Kernel Process

=cut

=abstract

Kernel Watcher Process

=cut

=includes

method: execute

=cut

=synopsis

  use Zing::Kernel;

  my $kernel = Zing::Kernel->new(scheme => ['MyApp', [], 1]);

  # $kernel->execute;

=cut

=libraries

Zing::Types

=cut

=inherits

Zing::Watcher

=cut

=attributes

journal: ro, opt, Channel
scheme: ro, req, Scheme

=cut

=description

This package provides a watcher process which launches the scheme and
supervises the resulting process, and thus is a system manager with control
over everything in the system.

=cut

=method execute

The execute method launches the scheme and executes the event-loops for all
processes.

=signature execute

execute() : Object

=example-1 execute

  # given: synopsis

  $kernel->execute;

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

$subs->example(-1, 'execute', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $MyApp::DATA, 1;

  $result
});

ok 1 and done_testing;
