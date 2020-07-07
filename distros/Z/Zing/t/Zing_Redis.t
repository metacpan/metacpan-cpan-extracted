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

Zing::Redis

=cut

=tagline

Redis Storage

=cut

=abstract

Redis Storage Abstraction

=cut

=includes

method: drop
method: dump
method: keys
method: load
method: lpull
method: lpush
method: recv
method: rpull
method: rpush
method: send
method: size
method: slot
method: term
method: test

=cut

=synopsis

  use Zing::Redis;

  my $redis = Zing::Redis->new;

  # $redis->drop;

=cut

=libraries

Zing::Types

=cut

=attributes

client: ro, opt, Redis

=cut

=description

This package provides a L<Redis> adapter for use with data storage
abstractions.

=cut

=method drop

The drop method removes (drops) the item from the datastore.

=signature drop

drop(Str $key) : Int

=example-1 drop

  # given: synopsis

  $redis->drop('model');

=cut

=method dump

The dump method encodes and returns the data provided as JSON.

=signature dump

dump(HashRef $data) : Str

=example-1 dump

  # given: synopsis

  $redis->dump({ status => 'ok' });

=cut

=method keys

The keys method returns a list of keys under the namespace of the datastore or
provided key.

=signature keys

keys(Str @keys) : ArrayRef[Str]

=example-1 keys

  # given: synopsis

  my $keys = $redis->keys('nodel');

=example-2 keys

  # given: synopsis

  $redis->send('model', { status => 'ok' });

  my $keys = $redis->keys('model');

=cut

=method rpull

The rpull method pops data off of the bottom of a list in the datastore.

=signature rpull

rpull(Str $key) : Maybe[HashRef]

=example-1 rpull

  # given: synopsis

  $redis->rpull('collection');

=example-2 rpull

  # given: synopsis

  $redis->rpush('collection', { status => 1 });
  $redis->rpush('collection', { status => 2 });

  $redis->rpull('collection');

=cut

=method lpull

The lpull method pops data off of the top of a list in the datastore.

=signature lpull

lpull(Str $key) : Maybe[HashRef]

=example-1 lpull

  # given: synopsis

  $redis->lpull('collection');

=example-2 lpull

  # given: synopsis

  $redis->rpush('collection', { status => 'ok' });

  $redis->lpull('collection');

=cut

=method rpush

The rpush method pushed data onto the bottom of a list in the datastore.

=signature rpush

rpush(Str $key, HashRef $val) : Int

=example-1 rpush

  # given: synopsis

  $redis->rpush('collection', { status => 'ok' });

=example-2 rpush

  # given: synopsis

  $redis->rpush('collection', { status => 'ok' });

  $redis->rpush('collection', { status => 'ok' });

=cut

=method load

The load method decodes the JSON data provided and returns the data as a hashref.

=signature load

load(Str $data) : HashRef

=example-1 load

  # given: synopsis

  $redis->load('{"status":"ok"}');

=cut

=method recv

The recv method fetches and returns data from the datastore by its key.

=signature recv

recv(Str $key) : Maybe[HashRef]

=example-1 recv

  # given: synopsis

  $redis->recv('model');

=example-2 recv

  # given: synopsis

  $redis->send('model', { status => 'ok' });

  $redis->recv('model');

=cut

=method send

The send method commits data to the datastore with its key and returns truthy.

=signature send

send(Str $key, HashRef $val) : Str

=example-1 send

  # given: synopsis

  $redis->send('model', { status => 'ok' });

=cut

=method size

The size method returns the size of a list in the datastore.

=signature size

size(Str $key) : Int

=example-1 size

  # given: synopsis

  my $size = $redis->size('collection');

=example-2 size

  # given: synopsis

  $redis->rpush('collection', { status => 'ok' });

  my $size = $redis->size('collection');

=cut

=method slot

The slot method returns the data from a list in the datastore by its index.

=signature slot

slot(Str $key, Int $pos) : Maybe[HashRef]

=example-1 slot

  # given: synopsis

  my $model = $redis->slot('collection', 0);

=example-2 slot

  # given: synopsis

  $redis->rpush('collection', { status => 'ok' });

  my $model = $redis->slot('collection', 0);

=cut

=method term

The term method generates a term (safe string) for the datastore.

=signature term

term(Str @keys) : Str

=example-1 term

  # given: synopsis

  $redis->term('model');

=cut

=method test

The test method returns truthy if the specific key (or datastore) exists.

=signature test

test(Str $key) : Int

=example-1 test

  # given: synopsis

  $redis->rpush('collection', { status => 'ok' });

  $redis->test('collection');

=example-2 test

  # given: synopsis

  $redis->drop('collection');

  $redis->test('collection');

=cut

=method lpush

The lpush method pushed data onto the top of a list in the datastore.

=signature lpush

lpush(Str $key, HashRef $val) : Int

=example-1 lpush

  # given: synopsis

  $redis->lpush('collection', { status => '1' });

=example-2 lpush

  # given: synopsis

  $redis->lpush('collection', { status => '0' });

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'drop', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);
  is $result, 0;

  $result
});

$subs->example(-1, 'dump', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  like $result, qr/"status"\s*:\s*"ok"/;

  $result
});

$subs->example(-1, 'keys', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is @$result, 0;

  $result
});

$subs->example(-2, 'keys', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is @$result, 1;

  $result
});

$subs->example(-1, 'rpull', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-2, 'rpull', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, {status => 2};

  $result
});

$subs->example(-1, 'lpull', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, {status => 1};

  $result
});

$subs->example(-2, 'lpull', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, {status => 'ok'};

  $result
});

$subs->example(-1, 'rpush', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 1;

  $result
});

$subs->example(-2, 'rpush', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 3;

  $result
});

$subs->example(-1, 'load', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, {status => 'ok'};

  $result
});

$subs->example(-1, 'recv', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-2, 'recv', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, {status => 'ok'};

  $result
});

$subs->example(-1, 'send', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'OK';

  $result
});

$subs->example(-1, 'size', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 3;

  $result
});

$subs->example(-2, 'size', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 4;

  $result
});

$subs->example(-1, 'slot', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-2, 'slot', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, {status => 'ok'};

  $result
});

$subs->example(-1, 'term', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  like $result, qr/^model$/;

  $result
});

$subs->example(-1, 'test', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-2, 'test', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-1, 'lpush', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 1;

  $result
});

$subs->example(-2, 'lpush', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 2;
  my $redis = Zing::Redis->new;
  my $top = $redis->lpull('collection');
  is_deeply $top, { status => '0' };

  $result
});

ok 1 and done_testing;
