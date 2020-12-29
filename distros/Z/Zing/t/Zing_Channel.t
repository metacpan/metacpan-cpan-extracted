use 5.014;

use strict;
use warnings;
use routines;

use lib 't/lib';

use Test::Auto;
use Test::More;
use Test::Zing;

=name

Zing::Channel

=cut

=tagline

Shared Communication

=cut

=abstract

Multi-process Communication Mechanism

=cut

=includes

method: recv
method: renew
method: reset
method: send
method: size
method: term

=cut

=synopsis

  use Zing::Channel;

  my $chan = Zing::Channel->new(name => 'share');

  # $chan->recv;

=cut

=libraries

Zing::Types

=cut

=inherits

Zing::PubSub

=cut

=attributes

name: ro, opt, Str

=cut

=description

This package represents a mechanism of interprocess communication and
synchronization via message passing.

=cut

=method recv

The recv method receives a single new message from the channel.

=signature recv

recv() : Maybe[HashRef]

=example-1 recv

  my $chan = Zing::Channel->new(name => 'recv-01');

  $chan->recv;

=example-2 recv

  my $chan = Zing::Channel->new(name => 'recv-02');

  $chan->send({ status => 'works' });

  $chan->recv;

=cut

=method renew

The renew method returns truthy if it resets the internal cursor, otherwise
falsy.

=signature renew

renew() : Int

=example-1 renew

  my $chan = Zing::Channel->new(name => 'renew-01');

  $chan->send({ status => 'works' }) for 1..5;

  $chan->renew;

=example-2 renew

  my $chan = Zing::Channel->new(name => 'renew-02');

  $chan->send({ status => 'works' }) for 1..5;
  $chan->recv;
  $chan->drop;

  $chan->renew;

=cut

=method reset

The reset method always reset the internal cursor and return truthy.

=signature reset

reset() : Int

=example-1 reset

  my $chan = Zing::Channel->new(name => 'reset-01');

  $chan->send({ status => 'works' }) for 1..5;
  $chan->recv;
  $chan->recv;

  $chan->reset;

=cut

=method send

The send method sends a new message to the channel and return the message
count.

=signature send

send(HashRef $value) : Int

=example-1 send

  my $chan = Zing::Channel->new(name => 'send-01');

  $chan->send({ status => 'works' });

=cut

=method size

The size method returns the message count of the channel.

=signature size

size() : Int

=example-1 size

  my $chan = Zing::Channel->new(name => 'size-01');

  $chan->send({ status => 'works' }) for 1..5;

  $chan->size;

=cut

=method term

The term method returns the name of the channel.

=signature term

term() : Str

=example-1 term

  my $chan = Zing::Channel->new(name => 'term-01');

  $chan->term;

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
  is_deeply $result, { status => 'works' };

  $result
});

$subs->example(-1, 'renew', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-2, 'renew', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 1;

  $result
});

$subs->example(-1, 'reset', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 1;

  $result
});

$subs->example(-1, 'send', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 1;

  $result
});

$subs->example(-1, 'size', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 5;

  $result
});

$subs->example(-1, 'term', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  like $result, qr/zing:main:global:channel:term-01/;

  $result
});

ok 1 and done_testing;
