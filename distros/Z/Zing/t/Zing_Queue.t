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

Zing::Queue

=cut

=tagline

Message Queue

=cut

=abstract

Generic Message Queue

=cut

=includes

method: recv
method: send
method: size
method: term

=cut

=synopsis

  use Zing::Queue;

  my $queue = Zing::Queue->new(name => 'tasks');

  # $queue->recv;

=cut

=libraries

Zing::Types

=cut

=inherits

Zing::PubSub

=cut

=description

This package provides a general-purpose message queue abstraction.

=cut

=method recv

The recv method receives a single new message from the channel.

=signature recv

recv() : Maybe[HashRef]

=example-1 recv

  # given: synopsis

  $queue->recv;

=example-2 recv

  # given: synopsis

  $queue->send({ restart => { after => 'cleanup' }});

  $queue->recv;

=cut

=method send

The send method sends a new message to the queue and returns the message count.

=signature send

send(HashRef $value) : Int

=example-1 send

  # given: synopsis

  $queue->send({ restart => { after => 'cleanup' }});

=example-2 send

  # given: synopsis

  $queue->drop;

  $queue->send({ restart => { after => 'cleanup' }});

=cut

=method size

The size method returns the number of messages in the queue.

=signature size

size() : Int

=example-1 size

  # given: synopsis

  my $size = $queue->size;

=cut

=method term

The term method generates a term (safe string) for the queue.

=signature term

term() : Str

=example-1 term

  # given: synopsis

  $queue->term;

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'recv', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-2, 'recv', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, { restart => { after => 'cleanup' }};

  $result
});

$subs->example(-1, 'send', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 1;

  $result
});

$subs->example(-2, 'send', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 1;

  $result
});

$subs->example(-1, 'term', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  like $result, qr/^zing:main:global:queue:tasks$/;

  $result
});

ok 1 and done_testing;
