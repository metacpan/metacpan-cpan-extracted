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

Zing::Fork

=cut

=tagline

Fork Manager

=cut

=abstract

Scheme Fork Manager

=cut

=includes

method: execute
method: monitor
method: sanitize
method: terminate

=cut

=synopsis

  use Zing::Fork;
  use Zing::Process;

  my $scheme = ['MyApp', [], 1];
  my $fork = Zing::Fork->new(scheme => $scheme, parent => Zing::Process->new);

  # $fork->execute;

=cut

=libraries

Zing::Types

=cut

=attributes

scheme: ro, req, Scheme
parent: ro, req, Process
processes: ro, opt, HashRef[Process]
space: ro, opt, Space

=cut

=description

This package provides provides a mechanism for forking and tracking processes,
as well as establishing the parent-child relationship. B<Note:> The C<$num>
part of the application scheme, i.e. C<['MyApp', [], $num]>, is ignored and
launching the desired forks requires calling L</execute> multiple times.

=cut

=method execute

The execute method forks a process based on the scheme, adds it to the process
list and returns a representation of the child process.

=signature execute

execute() : Process

=example-1 execute

  # given: synopsis

  my $process = $fork->execute;

=cut

=method monitor

The monitor method calls L<perlfunc/waitpid> on tracked processes and returns
the results as a pid/result map.

=signature monitor

monitor() : HashRef[Int]

=example-1 monitor

  # given: synopsis

  $fork->execute;
  $fork->execute;

  # forks still alive

  my $results = $fork->monitor;

  # { 1000 => 1000, ... }

=example-2 monitor

  # given: synopsis

  $fork->execute;
  $fork->execute;

  # forks are dead

  my $results = $fork->monitor;

  # { 1000 => -1, ... }

=cut

=method sanitize

The sanitize method removes inactive child processes from the process list and
returns the number of processes remaining.

=signature sanitize

sanitize() : Int

=example-1 sanitize

  # given: synopsis

  $fork->execute; # dead
  $fork->execute; # dead

  my $results = $fork->sanitize; # 0

=example-2 sanitize

  # given: synopsis

  $fork->execute; # live
  $fork->execute; # dead

  my $results = $fork->sanitize; # 1

=example-3 sanitize

  # given: synopsis

  $fork->execute; # live
  $fork->execute; # live

  my $results = $fork->sanitize; # 2

=cut

=method terminate

The terminate method call L<perlfunc/kill> and sends a signal to all tracked
processes and returns the results as a pid/result map.

=signature terminate

terminate(Str $signal = 'kill') : HashRef[Int]

=example-1 terminate

  # given: synopsis

  $fork->execute;
  $fork->execute;

  my $results = $fork->terminate; # kill

=example-2 terminate

  # given: synopsis

  $fork->execute;
  $fork->execute;

  my $results = $fork->terminate('term');

=example-3 terminate

  # given: synopsis

  $fork->execute;
  $fork->execute;

  my $results = $fork->terminate('usr2');

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

  $result
});

$subs->example(-1, 'monitor', 'method', fun($tryable) {
  local $ENV{ZING_TEST_WAIT} = 1;
  ok my $result = $tryable->result;
  ok grep {$_ != -1} values %$result;

  $result
});

$subs->example(-2, 'monitor', 'method', fun($tryable) {
  local $ENV{ZING_TEST_WAIT} = -1;
  ok my $result = $tryable->result;
  ok grep {$_ == -1} values %$result;

  $result
});

$subs->example(-1, 'sanitize', 'method', fun($tryable) {
  local $ENV{ZING_TEST_WAIT} = -1;
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-2, 'sanitize', 'method', fun($tryable) {
  local $ENV{ZING_TEST_WAIT_ONE} = 1;
  ok my $result = $tryable->result;
  is $result, 1;

  $result
});

$subs->example(-3, 'sanitize', 'method', fun($tryable) {
  local $ENV{ZING_TEST_WAIT} = 1;
  ok my $result = $tryable->result;
  is $result, 2;

  $result
});

$subs->example(-1, 'terminate', 'method', fun($tryable) {
  local $ENV{ZING_TEST_KILL} = -1;
  ok my $result = $tryable->result;
  my $assumed = { map +($_, -1), keys %$result };
  is_deeply $result, $assumed;

  $result
});

$subs->example(-2, 'terminate', 'method', fun($tryable) {
  local $ENV{ZING_TEST_KILL} = -1;
  ok my $result = $tryable->result;
  my $assumed = { map +($_, -1), keys %$result };
  is_deeply $result, $assumed;

  $result
});

$subs->example(-3, 'terminate', 'method', fun($tryable) {
  local $ENV{ZING_TEST_KILL} = -1;
  ok my $result = $tryable->result;
  my $assumed = { map +($_, -1), keys %$result };
  is_deeply $result, $assumed;

  $result
});

ok 1 and done_testing;
