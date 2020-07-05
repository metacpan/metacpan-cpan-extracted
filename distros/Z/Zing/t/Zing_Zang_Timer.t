use 5.014;

use strict;
use warnings;
use routines;

use lib 't/app';
use lib 't/lib';

use Test::Auto;
use Test::More;
use Test::Zing;

use Zing::Queue;

=name

Zing::Zang::Timer

=cut

=tagline

Timer Process

=abstract

Timer Process Implementation

=cut

=synopsis

  use Zing::Zang::Timer;

  my $zang = Zing::Zang::Timer->new(
    schedules => [['@minute', ['tasks'], {do => 1}]],
  );

  # $zang->execute;

=cut

=libraries

Zing::Types

=cut

=inherits

Zing::Timer

=cut

=attributes

on_perform: ro, opt, Maybe[CodeRef]
on_receive: ro, opt, Maybe[CodeRef]
schedules: ro, req, ArrayRef[Schedule]

=cut

=description

This package provides a L<Zing::Timer> which uses callbacks and doesn't need to
be subclassd. It supports providing a process C<perform> method as
C<on_perform> and a C<receive> method as C<on_receive> which operate as
expected, and also a C<schedules> attribute which takes a list of schedules to
enforce.

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  my $queue = Zing::Queue->new(name => 'tasks');
  $queue->drop;
  ok my $result = $tryable->result;
  $result->execute;
  my $data = $queue->recv;
  is_deeply $data, {do => 1};

  $result
});

ok 1 and done_testing;
