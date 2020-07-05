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

Zing::PubSub

=cut

=tagline

Pub/Sub Store

=cut

=abstract

Generic Pub/Sub Store

=cut

=includes

method: poll
method: recv
method: send
method: term

=cut

=synopsis

  use Zing::PubSub;

  my $pubsub = Zing::PubSub->new(name => 'tasks');

  # $pubsub->recv('priority-1');

=cut

=libraries

Zing::Types

=cut

=inherits

Zing::Repo

=cut

=description

This package provides a general-purpose publish/subscribe store abstraction.

=cut

=method poll

The poll method returns a L<Zing::Poll> object which can be used to perform a
blocking-fetch from the store.

=signature poll

poll(Str $key) : Poll

=example-1 poll

  # given: synopsis

  $pubsub->poll('priority-1');

=cut

=method recv

The recv method receives a single new message from the store.

=signature recv

recv(Str $key) : Maybe[HashRef]

=example-1 recv

  # given: synopsis

  $pubsub->recv('priority-1');

=example-2 recv

  # given: synopsis

  $pubsub->send('priority-1', { task => 'restart' });

  $pubsub->recv('priority-1');

=cut

=method send

The send method sends a new message to the store and return the message count.

=signature send

send(Str $key, HashRef $value) : Int

=example-1 send

  # given: synopsis

  $pubsub->send('priority-1', { task => 'restart' });

=example-2 send

  # given: synopsis

  $pubsub->drop;

  $pubsub->send('priority-1', { task => 'restart' });

=cut

=method term

The term method return a term (safe string) for the store.

=signature term

term(Str @keys) : Str

=example-1 term

  # given: synopsis

  $pubsub->term('priority-1');

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'poll', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'recv', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-2, 'recv', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, { task => 'restart' };

  $result
});

$subs->example(-1, 'send', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 1;

  $result
});

$subs->example(-2, 'send', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 2;

  $result
});

$subs->example(-1, 'term', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  like $result, qr/:priority-1$/;

  $result
});

ok 1 and done_testing;
