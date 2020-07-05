use 5.014;

use strict;
use warnings;
use routines;

use lib 't/app';
use lib 't/lib';

use Test::Auto;
use Test::More;
use Test::Zing;

use Zing::Queue;

=name

Zing::Zang::Spawner

=cut

=tagline

Process Spawner

=abstract

Process Spawner Implementation

=cut

=synopsis

  use Zing::Zang::Spawner;

  my $zang = Zing::Zang::Spawner->new(
    queues => ['launch'],
  );

  # $zang->execute;

=cut

=libraries

Zing::Types

=cut

=inherits

Zing::Spawner

=cut

=attributes

on_perform: ro, opt, Maybe[CodeRef]
on_receive: ro, opt, Maybe[CodeRef]
queues: ro, req, ArrayRef[Str]

=cut

=description

This package provides a L<Zing::Spawner> which uses callbacks and doesn't need
to be subclassd. It supports providing a list of queues to listen to which will
fork a process that loads, instantiates and executes schemes recevied.

=cut

package MyApp;

use parent 'Zing::Process';

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;
  my $queue = Zing::Queue->new(name => 'launch');
  $queue->send({ scheme => ['MyApp', [], 1] });
  $result->execute;

  $result
});

ok 1 and done_testing;
