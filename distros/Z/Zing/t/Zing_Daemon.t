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

Zing::Daemon

=cut

=tagline

Process Daemon

=cut

=abstract

Daemon Process Management

=cut

=includes

method: execute
method: fork
method: start

=cut

=synopsis

  use Zing;
  use Zing::Daemon;

  my $scheme = ['MyApp', [], 1];
  my $daemon = Zing::Daemon->new(name => 'app', app => Zing->new(scheme => $scheme));

  # $daemon->start;

=cut

=libraries

Zing::Types

=cut

=attributes

app: ro, req, Zing
name: ro, req, Str
log: ro, opt, Logger
pid_dir: ro, opt, Str
pid_file: ro, opt, Str
pid_path: ro, opt, Str

=cut

=description

This package provides the mechanisms for running a L<Zing> application as a
daemon process.

=cut

=method execute

The execute method forks the application and creates a pid file under the
L</pid_path>.

=signature execute

execute() : Int

=example-1 execute

  # given: synopsis

  my $exit = $daemon->execute;

=cut

=method fork

The fork method forks the application and returns a pid.

=signature fork

fork() : Int

=example-1 fork

  # given: synopsis

  my $pid = $daemon->fork;

=cut

=method start

The start method executes the application and exits the program with the proper
exit code.

=signature start

start() : Any

=example-1 start

  # given: synopsis

  $daemon->start;

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
  ok !(my $result = $tryable->result); # good

  $result
});

$subs->example(-1, 'fork', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'start', 'method', fun($tryable) {
  ok !(my $result = $tryable->result); # good

  $result
});

ok 1 and done_testing;
