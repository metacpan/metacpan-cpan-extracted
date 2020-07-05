use 5.014;

use strict;
use warnings;
use routines;

use lib 't/lib';

use Test::Auto;
use Test::More;
use Test::Zing;

=name

Zing

=cut

=tagline

Multi-Process Management System

=cut

=abstract

Actor Toolkit and Multi-Process Management System

=cut

=includes

method: start

=cut

=attributes

scheme: ro, req, Scheme

=cut

=synopsis

  use Zing;

  my $zing = Zing->new(scheme => ['MyApp', [], 1]);

  # $zing->execute;

=cut

=libraries

Zing::Types

=cut

=inherits

Zing::Watcher

=cut

=description

This distribution includes an actor-model architecture toolkit and
multi-process management system which provides primatives for building
resilient, reactive, concurrent, distributed message-driven applications in
Perl 5. If you're unfamiliar with this architectural pattern, learn more about
L<"the actor model"|https://en.wikipedia.org/wiki/Actor_model>.

=cut

=method start

The start method builds a L<Zing::Kernel> and executes its event-loop.

=signature start

start() : Kernel

=example-1 start

  # given: synopsis

  $zing->start;

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

$subs->example(-1, 'start', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $MyApp::DATA, 1;

  $result
});

ok 1 and done_testing;
