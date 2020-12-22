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

method: fork
method: restart
method: start
method: stop

=cut

=synopsis

  use Zing::Cartridge;
  use Zing::Daemon;

  my $daemon = Zing::Daemon->new(
    cartridge => Zing::Cartridge->new(
      name => 'example',
      scheme => ['MyApp', [], 1],
    )
  );

  # $daemon->start;

=cut

=libraries

Zing::Types

=cut

=inherits

Zing::Entity

=cut

=attributes

cartridge: ro, req, Cartridge
journal: ro, opt, Journal
kernel: ro, opt, Zing
log_filter_from: ro, opt, Str
log_filter_queries: ro, opt, ArrayRef[Str]
log_filter_tag: ro, opt, Str
log_level: ro, opt, Str
log_reset: ro, opt, Bool
log_verbose: ro, opt, Bool
logger: ro, opt, Logger

=cut

=description

This package provides the mechanisms for running a L<Zing> application
as a daemon process.

=cut

=method fork

The fork method forks the application and returns a pid.

=signature fork

fork() : Int

=example-1 fork

  # given: synopsis

  my $pid = $daemon->fork;

=cut

=method restart

The restart method stops and then starts the application and creates a pid file
under the L<Zing::Cartridge/pidfile>.

=signature restart

restart() : Bool

=example-1 restart

  use FlightRecorder;
  use Zing::Cartridge;
  use Zing::Daemon;

  my $daemon = Zing::Daemon->new(
    logger => FlightRecorder->new(auto => undef),
    cartridge => Zing::Cartridge->new(
      name => 'example',
      scheme => ['MyApp', [], 1],
    )
  );

  $daemon->restart;

=cut

=method start

The start method forks the application and creates a pid file under the
L<Zing::Cartridge/pidfile>.

=signature start

start() : Bool

=example-1 start

  use FlightRecorder;
  use Zing::Cartridge;
  use Zing::Daemon;

  my $daemon = Zing::Daemon->new(
    logger => FlightRecorder->new(auto => undef),
    cartridge => Zing::Cartridge->new(
      name => 'example',
      scheme => ['MyApp', [], 1],
    )
  );

  $daemon->start;

=cut

=method stop

The stop method stops the application and removes the pid file under the
L<Zing::Cartridge/pidfile>.

=signature stop

stop() : Bool

=example-1 stop

  use FlightRecorder;
  use Zing::Cartridge;
  use Zing::Daemon;

  my $daemon = Zing::Daemon->new(
    logger => FlightRecorder->new(auto => undef),
    cartridge => Zing::Cartridge->new(
      name => 'example',
      scheme => ['MyApp', [], 1],
    )
  );

  $daemon->stop;

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

$subs->example(-1, 'fork', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'restart', 'method', fun($tryable) {
  ok my $result = $tryable->result; # good

  $result
});

$subs->example(-1, 'start', 'method', fun($tryable) {
  ok my $result = $tryable->result; # good

  $result
});

$subs->example(-1, 'stop', 'method', fun($tryable) {
  ok my $result = $tryable->result; # good

  $result
});

ok 1 and done_testing;
