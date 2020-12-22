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

Zing::Scheduler

=cut

=tagline

Scheme Launcher

=cut

=abstract

Default Scheme Launcher

=cut

=includes

method: queues

=cut

=synopsis

  use Zing::Scheduler;

  my $scheduler = Zing::Scheduler->new;

  # $scheduler->execute;

=cut

=libraries

Zing::Types

=cut

=inherits

Zing::Launcher

=cut

=description

This package provides a local (node-specific, not cluster-wide) launcher
process which is a type of worker process which loads, instantiates, and
executes L<"schemes"|Zing::Types/scheme>.

=cut

=method queues

The queues method executes something which triggers something else.

=signature queues

queues() : ArrayRef[Str]

=example-1 queues

  # given: synopsis

  my $queues = $scheduler->queues;

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'queues', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['$scheduled'];

  $result
});

ok 1 and done_testing;
