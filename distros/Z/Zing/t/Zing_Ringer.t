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

Zing::Ringer

=cut

=tagline

Scheme Ring

=cut

=abstract

Multi-Scheme Assembly Ring

=cut

=includes

method: reify

=cut

=synopsis

  use Zing::Ringer;

  my $ring = Zing::Ringer->new(schemes => [
    ['MyApp', [], 1],
    ['MyApp', [], 1],
  ]);

  # $ring->execute;

=cut

=libraries

Zing::Types

=cut

=inherits

Zing::Ring

=cut

=attributes

processes: ro, opt, ArrayRef[Process]
schemes: ro, req, ArrayRef[Scheme]

=cut

=description

This package provides a mechanism for joining two (or more) processes from
their scheme definitions and executes them as one in a turn-based manner.

=cut

=method reify

The reify method loads, instantiates, and returns a L<Zing::Process> derived
object from an application scheme.

=signature reify

reify(Scheme $scheme) : Process

=example-1 reify

  # given: synopsis

  $ring->reify(['MyApp', [], 1]);

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

$subs->example(-1, 'reify', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

ok 1 and done_testing;
