use 5.014;

use strict;
use warnings;
use routines;

use lib 't/app';
use lib 't/lib';

use Test::Auto;
use Test::More;
use Test::Trap;
use Test::Zing;

=name

Zing::Cli

=cut

=tagline

Command-line Interface

=cut

=abstract

Command-line Process Management

=cut

=includes

method: main

=cut

=synopsis

  use Zing::Cli;

  my $cli = Zing::Cli->new;

  # $cli->handle('main');

=cut

=libraries

Zing::Types

=cut

=inherits

Data::Object::Cli

=cut

=description

This package provides a command-line interface for managing L<Zing>
applications. See the L<zing> documentation for interface arguments and
options.

=cut

=method main

The main method executes the command-line interface and displays help text or
launches applications.

=signature main

main() : Any

=example-1 main

  # given: synopsis

  # e.g.
  # zing start once -I t/lib -a t/app
  # pass

  $cli->handle('main');

=example-2 main

  # given: synopsis

  # e.g.
  # zing start unce -I t/lib -a t/app
  # fail (not exist)

  $cli->handle('main');

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'main', 'method', fun($tryable) {
  my $result;

  local @ARGV = ('start', 'once', '-I', 't/lib', '-a', 't/app');
  trap { ok $result = $tryable->result }; # exit 0 is good
  is $trap->exit, 0;

  $result
});

$subs->example(-2, 'main', 'method', fun($tryable) {
  my $result;

  local @ARGV = ('start', 'unce', '-I', 't/lib', '-a', 't/app');
  trap { ok ($result = $tryable->result) }; # exit 1 is fail
  is $trap->exit, 1;

  $result
});

ok 1 and done_testing;
