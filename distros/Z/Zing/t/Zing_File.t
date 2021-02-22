use 5.014;

use strict;
use warnings;
use routines;

use lib 't/lib';

use Test::Auto;
use Test::More;
use Test::Zing;

=name

Zing::File

=cut

=tagline

Supervision Tree Generator

=cut

=abstract

Zing Supervision Tree Generator

=cut

=includes

function: scheme
method: interpret

=cut

=synopsis

  use Zing::File;

  my $file = Zing::File->new;

  # $file->interpret([['MyApp::Client', [], 2], ['MyApp::Server', [], 1]])

=cut

=libraries

Zing::Types

=cut

=description

This package provides a mechnism for generating executable supervision trees.

=cut

=function scheme

The scheme function converts the expression provided, which itself is either a
scheme or a list of schemes (which can be nested), to a scheme representing a
supervision tree with L<Zing::Ringer> and L<Zing::Watcher> processes.

=signature scheme

scheme(Scheme | ArrayRef[Scheme | ArrayRef] $expr) : Scheme

=example-1 scheme

  use Zing::File 'scheme';

  scheme([['MyApp::Client', [], 2], ['MyApp::Server', [], 1]]);

=cut

=method interpret

The interpret method passes the expression provided to the L</scheme> function
to generate a scheme.

=signature interpret

interpret(Scheme | ArrayRef[Scheme | ArrayRef] $expr) : Scheme

=example-1 interpret

  # given: synopsis

  $file->interpret([['MyApp::Client', [], 2], ['MyApp::Server', [], 1]]);

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'scheme', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  # main process
  is $result->[0], 'Zing::Ringer';
  is $result->[1][0], 'schemes';
  # nested scheme #1
  is $result->[1][1][0][0], 'Zing::Watcher';
  is $result->[1][1][0][1][0], 'on_scheme';
  is ref $result->[1][1][0][1][1], 'CODE';
  is $result->[1][1][0][2], 1;
  is_deeply $result->[1][1][0][1][1]->(), ['MyApp::Client', [], 2];
  # nested scheme #2
  is $result->[1][1][1][0], 'Zing::Watcher';
  is $result->[1][1][1][1][0], 'on_scheme';
  is ref $result->[1][1][1][1][1], 'CODE';
  is $result->[1][1][1][2], 1;
  is_deeply $result->[1][1][1][1][1]->(), ['MyApp::Server', [], 1];
  # main process count
  is $result->[2], 1;

  $result
});

$subs->example(-1, 'interpret', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

ok 1 and done_testing;
