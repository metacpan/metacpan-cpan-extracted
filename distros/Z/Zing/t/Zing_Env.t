use 5.014;

use strict;
use warnings;
use routines;

use lib 't/lib';

use Test::Auto;
use Test::More;
use Test::Zing;

=name

Zing::Env

=cut

=tagline

Zing Environment

=cut

=abstract

Zing Environment Abstraction

=cut

=synopsis

  use Zing::Env;

  my $env = Zing::Env->new;

=cut

=libraries

Zing::Types

=cut

=attributes

app: ro, opt, App
appdir: ro, opt, Maybe[Str]
config: ro, opt, HashRef[ArrayRef]
debug: ro, opt, Maybe[Bool]
encoder: ro, opt, Maybe[Str]
handle: ro, opt, Maybe[Str]
home: ro, opt, Maybe[Str]
host: ro, opt, Maybe[Str]
piddir: ro, opt, Maybe[Str]
store: ro, opt, Maybe[Str]
target: ro, opt, Maybe[Name]

=cut

=description

This package provides a L<Zing> environment abstraction to be used by
L<Zing::App> and other environment-aware objects.

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

ok 1 and done_testing;
