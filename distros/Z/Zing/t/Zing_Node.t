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

Zing::Node

=cut

=tagline

Node Information

=abstract

Process Node Information

=cut

=includes

method: identifier

=cut

=synopsis

  use Zing::Node;

  my $node = Zing::Node->new;

=cut

=libraries

Zing::Types

=cut

=attributes

name: ro, opt, Str
pid: ro, opt, Str
server: ro, opt, Server

=cut

=description

This package provides represents a process within a network and cluster.

=cut

=method identifier

The identifier method generates and returns a cross-cluster unique identifier.

=signature identifier

identifier() : Str

=example-1 identifier

  # given: synopsis

  my $id = $node->identifier;

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'identifier', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  like $result, qr/^[\d\.]+:\d+:\d+:\d+$/;

  $result
});

ok 1 and done_testing;
