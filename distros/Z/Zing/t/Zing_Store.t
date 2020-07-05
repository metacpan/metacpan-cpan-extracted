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

Zing::Store

=cut

=tagline

Storage Abstraction

=cut

=abstract

Redis Storage Abstraction

=cut

=includes

method: drop
method: dump
method: keys
method: pop
method: pull
method: push
method: load
method: recv
method: send
method: size
method: slot
method: term
method: test

=cut

=synopsis

  use Zing::Store;

  my $store = Zing::Store->new;

  # $store->drop;

=cut

=libraries

Zing::Types

=cut

=attributes

redis: ro, opt, Redis

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

  $store->drop('model');

=cut

=method dump

The dump method encodes and returns the data provided as JSON.

=signature dump

dump(HashRef $data) : Str

=example-1 dump

  # given: synopsis

  $store->dump({ status => 'ok' });

=cut

=method keys

The keys method returns a list of keys under the namespace of the datastore or
provided key.

=signature keys

keys(Str @keys) : ArrayRef[Str]

=example-1 keys

  # given: synopsis

  my $keys = $store->keys('nodel');

=example-2 keys

  # given: synopsis

  $store->send('model', { status => 'ok' });

  my $keys = $store->keys('model');

=cut

=method pop

The pop method pops data off of the bottom of a list in the datastore.

=signature pop

pop(Str $key) : Maybe[HashRef]

=example-1 pop

  # given: synopsis

  $store->pop('collection');

=example-2 pop

  # given: synopsis

  $store->push('collection', { status => 1 });
  $store->push('collection', { status => 2 });

  $store->pop('collection');

=cut

=method pull

The pull method pops data off of the top of a list in the datastore.

=signature pull

pull(Str $key) : Maybe[HashRef]

=example-1 pull

  # given: synopsis

  $store->pull('collection');

=example-2 pull

  # given: synopsis

  $store->push('collection', { status => 'ok' });

  $store->pull('collection');

=cut

=method push

The push method pushed data onto the bottom of a list in the datastore.

=signature push

push(Str $key, HashRef $val) : Int

=example-1 push

  # given: synopsis

  $store->push('collection', { status => 'ok' });

=example-2 push

  # given: synopsis

  $store->push('collection', { status => 'ok' });

  $store->push('collection', { status => 'ok' });

=cut

=method load

The load method decodes the JSON data provided and returns the data as a hashref.

=signature load

load(Str $data) : HashRef

=example-1 load

  # given: synopsis

  $store->load('{"status":"ok"}');

=cut

=method recv

The recv method fetches and returns data from the datastore by its key.

=signature recv

recv(Str $key) : Maybe[HashRef]

=example-1 recv

  # given: synopsis

  $store->recv('model');

=example-2 recv

  # given: synopsis

  $store->send('model', { status => 'ok' });

  $store->recv('model');

=cut

=method send

The send method commits data to the datastore with its key and returns truthy.

=signature send

send(Str $key, HashRef $val) : Str

=example-1 send

  # given: synopsis

  $store->send('model', { status => 'ok' });

=cut

=method size

The size method returns the size of a list in the datastore.

=signature size

size(Str $key) : Int

=example-1 size

  # given: synopsis

  my $size = $store->size('collection');

=example-2 size

  # given: synopsis

  $store->push('collection', { status => 'ok' });

  my $size = $store->size('collection');

=cut

=method slot

The slot method returns the data from a list in the datastore by its index.

=signature slot

slot(Str $key, Int $pos) : Maybe[HashRef]

=example-1 slot

  # given: synopsis

  my $model = $store->slot('collection', 0);

=example-2 slot

  # given: synopsis

  $store->push('collection', { status => 'ok' });

  my $model = $store->slot('collection', 0);

=cut

=method term

The term method generates a term (safe string) for the datastore.

=signature term

term(Str @keys) : Str

=example-1 term

  # given: synopsis

  $store->term('model');

=cut

=method test

The test method returns truthy if the specific key (or datastore) exists.

=signature test

test(Str $key) : Int

=example-1 test

  # given: synopsis

  $store->push('collection', { status => 'ok' });

  $store->test('collection');

=example-2 test

  # given: synopsis

  $store->drop('collection');

  $store->test('collection');

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

$subs->example(-1, 'pop', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-2, 'pop', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, {status => 2};

  $result
});

$subs->example(-1, 'pull', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, {status => 1};

  $result
});

$subs->example(-2, 'pull', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, {status => 'ok'};

  $result
});

$subs->example(-1, 'push', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 1;

  $result
});

$subs->example(-2, 'push', 'method', fun($tryable) {
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

ok 1 and done_testing;
