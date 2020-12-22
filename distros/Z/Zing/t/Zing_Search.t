use 5.014;

use strict;
use warnings;
use routines;

use lib 't/lib';

use Test::Auto;
use Test::More;
use Test::Zing;

=name

Zing::Search

=cut

=tagline

Search Abstraction

=cut

=abstract

Storage Search Abstraction

=cut

=includes

method: any
method: for
method: objects
method: process
method: query
method: results
method: using
method: where

=cut

=synopsis

  use Zing::Search;

  my $search = Zing::Search->new;

  # $search->query;

=cut

=libraries

Zing::Types

=cut

=inherits

Zing::Entity

=cut

=attributes

handle: ro, opt, Str
symbol: ro, opt, Str
bucket: ro, opt, Str
system: ro, opt, Name
target: ro, opt, Str
store: ro, opt, Store

=cut

=description

This package provides a storage search abstraction.

=cut

=method any

The any method returns a search to query for any C<handle>, C<target>,
C<symbol> and C<bucket>.

=signature any

any() : Object

=example-1 any

  # given: synopsis

  $search = $search->any;

=cut

=method for

The for method returns a search to query for any object of the given type
within the defined C<handle> and C<target>.

=signature for

for(Str $type) : Object

=example-1 for

  # given: synopsis

  $search = $search->for('queue');

=cut

=method objects

The objects method returns a collection of objects derived from the query
criteria.

=signature objects

objects() : ArrayRef[Object]

=example-1 objects

  # given: synopsis

  my $objects = $search->objects;

=cut

=example-2 objects

  # given: synopsis

  use Zing::KeyVal;
  use Zing::PubSub;

  my $keyval = Zing::KeyVal->new(name => rand);
  $keyval->send({ sent => 1 });

  my $pubsub = Zing::PubSub->new(name => rand);
  $pubsub->send({ sent => 1 });

  my $objects = $search->objects;

=cut

=method process

The process method executes the C<callback> for each term in the search
results.

=signature process

process(CodeRef $callback) : Object

=example-1 process

  # given: synopsis

  $search = $search->process(sub {
    my ($term) = @_;
  });

=cut

=method query

The query method returns the query string used to produce search results.

=signature query

query() : Str

=example-1 query

  # given: synopsis

  my $query = $search->query;

=cut

=method results

The results method performs a search and returns a collection of terms that
meet the criteria.

=signature results

results() : ArrayRef[Str]

=example-1 results

  # given: synopsis

  my $results = $search->results;

=cut

=example-2 results

  # given: synopsis

  use Zing::KeyVal;
  use Zing::PubSub;

  my $keyval = Zing::KeyVal->new(name => rand);
  $keyval->send({ sent => 1 });

  my $pubsub = Zing::PubSub->new(name => rand);
  $pubsub->send({ sent => 1 });

  my $results = $search->results;

=cut

=method using

The using method modifies the search criteria to match the term of the
provided repo or L<Zing::Repo> derived object.

=signature using

using(Repo $repo) : Object

=example-1 using

  # given: synopsis

  use Zing::Queue;

  my $tasks = Zing::Queue->new(name => 'tasks');

  $search = $search->using($tasks);

=cut

=method where

The where method modifies the search criteria based on the arguments
provided.

=signature where

where(Str %args) : Object

=example-1 where

  # given: synopsis

  $search = $search->where(
    handle => 'myapp',
    target => 'us-west',
  );

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'any', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result->system, 'zing';
  is $result->handle, '*';
  is $result->target, '*';
  is $result->symbol, '*';
  is $result->bucket, '*';

  $result
});

$subs->example(-1, 'for', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result->system, 'zing';
  is $result->handle, 'main';
  is $result->target, 'global';
  is $result->symbol, 'queue';
  is $result->bucket, '*';

  $result
});

$subs->example(-1, 'objects', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

$subs->example(-2, 'objects', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  my $has_keyval = grep { ref($_) eq 'Zing::KeyVal' } @$result;
  my $has_pubsub = grep { ref($_) eq 'Zing::PubSub' } @$result;

  ok $has_keyval;
  ok $has_pubsub;

  $result->[0]->drop;
  $result->[1]->drop;

  $result
});

$subs->example(-1, 'process', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'query', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'zing:*:*:*:*';

  $result
});

$subs->example(-1, 'results', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

$subs->example(-2, 'results', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  my $has_keyval = grep /:keyval:/, @$result;
  my $has_pubsub = grep /:pubsub:/, @$result;

  ok $has_keyval;
  ok $has_pubsub;

  for my $object (@{Zing::Search->new->objects}) {
    $object->drop;
  }

  $result
});

$subs->example(-1, 'using', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result->system, 'zing';
  is $result->handle, 'main';
  is $result->target, 'global';
  is $result->symbol, 'queue';
  is $result->bucket, 'tasks';

  $result
});

$subs->example(-1, 'where', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result->system, 'zing';
  is $result->handle, 'myapp';
  is $result->target, 'us-west';
  is $result->symbol, '*';
  is $result->bucket, '*';

  $result
});

ok 1 and done_testing;
