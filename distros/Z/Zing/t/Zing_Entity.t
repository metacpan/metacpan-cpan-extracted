use 5.014;

use strict;
use warnings;
use routines;

use lib 't/lib';

use Test::Auto;
use Test::More;
use Test::Zing;

=name

Zing::Entity

=cut

=tagline

Environment-aware Base Class

=cut

=abstract

Environment-aware Abstract Base Class

=cut

=synopsis

  use Zing::Entity;

  my $entity = Zing::Entity->new;

  # $entity->app;
  # $entity->env;

=cut

=libraries

Zing::Types

=cut

=inherits

Zing::Class

=cut

=attributes

app: ro, opt, App
env: ro, opt, Env

=cut

=description

This package provides an environment-aware abstract base class for L<Zing>
classes that need to be environment-aware.

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

ok 1 and done_testing;
