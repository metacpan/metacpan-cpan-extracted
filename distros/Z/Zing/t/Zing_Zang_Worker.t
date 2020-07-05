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

Zing::Zang::Worker

=cut

=tagline

Worker Process

=abstract

Worker Process Implementation

=cut

=synopsis

  use Zing::Zang::Worker;

  my $zang = Zing::Zang::Worker->new(
    on_handle => sub {
      my ($self, $name, $data) = @_;

      $self->{handled} = [$name, $data];
    },
    queues => ['tasks']
  );

  # $zang->execute;

=cut

=libraries

Zing::Types

=cut

=inherits

Zing::Worker

=cut

=attributes

on_handle: ro, opt, Maybe[CodeRef]
on_perform: ro, opt, Maybe[CodeRef]
on_receive: ro, opt, Maybe[CodeRef]
queues: ro, req, ArrayRef[Str]

=cut

=description

This package provides a L<Zing::Worker> which uses callbacks and doesn't need
to be subclassd. It supports providing a process C<perform> method as
C<on_perform> and a C<receive> method as C<on_receive> which operate as
expected, and also a C<handle> method as C<on_handle> which is executed
whenever a message is received from one of the queue(s).

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  my $queue = Zing::Queue->new(name => 'tasks');
  $queue->drop;
  ok my $result = $tryable->result;
  $queue->send({ perform => 'restart' });
  $result->execute;
  ok $result->{handled};
  is_deeply $result->{handled}, ['tasks', {perform => 'restart'}];

  $result
});

ok 1 and done_testing;
