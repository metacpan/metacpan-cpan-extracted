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

Zing::Server

=cut

=tagline

Server Information

=abstract

Process Server Information

=cut

=synopsis

  use Zing::Server;

  my $server = Zing::Server->new;

=cut

=libraries

Zing::Types

=cut

=attributes

name: ro, opt, Str

=cut

=description

This package provides represents a server within a network and cluster.

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

ok 1 and done_testing;
