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

Zing::System

=cut

=tagline

System Command Process

=abstract

System Command Process Abstraction

=cut

=synopsis

  use Zing::System;

  my $system = Zing::System->new(
    command => ['perl -v | head -n 2 | tail -n 1'],
  );

  # $system->execute;

=cut

=libraries

Zing::Types

=cut

=inherits

Zing::Process

=cut

=attributes

command: ro, req, ArrayRef[Str]

=cut

=description

This package provides an actor abstraction which executes a system command
using C<exec>.

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

ok 1 and done_testing;
