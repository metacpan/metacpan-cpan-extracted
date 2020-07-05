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

Zing::Simple

=cut

=tagline

Simple Process

=abstract

Simple Process

=cut

=synopsis

  package MyApp;

  use parent 'Zing::Simple';

  sub perform {
    time;
  }

  package main;

  my $myapp = MyApp->new;

  # $myapp->execute;

=cut

=libraries

Zing::Types

=cut

=inherits

Zing::Process

=cut

=description

This package provides a L<Zing::Process> which ignores its mailbox and only
invokes its C<perform> method.

=cut

=scenario perform

The perform method is meant to be implemented by a subclass and is
automatically invoked iteratively by the event-loop.

=example perform

  # given: synopsis

  $myapp->perform;

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('MyApp');
  ok $result->isa('Zing::Simple');

  $result
});

$subs->scenario('perform', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

ok 1 and done_testing;
