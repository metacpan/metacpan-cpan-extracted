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

Zing::Repo

=cut

=tagline

Generic Store

=cut

=abstract

Generic Store Abstraction

=cut

=includes

method: drop
method: ids
method: keys
method: term
method: test

=cut

=synopsis

  use Zing::Repo;

  my $repo = Zing::Repo->new(name => 'repo');

  # $repo->recv('text-1');

=cut

=libraries

Zing::Types

=cut

=attributes

name: ro, req, Str
server: ro, opt, Server
store: ro, opt, Store
target: ro, opt, Enum[qw(global local)]

=cut

=description

This package provides a general-purpose data storage abstraction.

=cut

=method drop

The drop method returns truthy if the data was removed from the store.

=signature drop

drop(Str @keys) : Int

=example-1 drop

  # given: synopsis

  $repo->drop('text-1');

=cut

=method ids

The ids method returns a list of IDs (keys) stored under the datastore namespace.

=signature ids

ids() : ArrayRef[Str]

=example-1 ids

  # given: synopsis

  my $ids = $repo->ids;

=cut

=method keys

The keys method returns a list of fully-qualified keys stored under the
datastore namespace.

=signature keys

keys() : ArrayRef[Str]

=example-1 keys

  # given: synopsis

  my $keys = $repo->keys;

=cut

=method term

The term method generates a term (safe string) for the datastore.

=signature term

term(Str @keys) : Str

=example-1 term

  # given: synopsis

  my $term = $repo->term('text-1');

=cut

=method test

The test method returns truthy if the specific key (or datastore) exists.

=signature test

test(Str @keys) : Int

=example-1 test

  # given: synopsis

  $repo->test('text-1');

=example-2 test

  # given: synopsis

  $repo->store->send($repo->term('text-1'), { test => time });

  $repo->test('text-1');

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

  $result
});

$subs->example(-1, 'ids', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'keys', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'term', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  my $local = qr/zing:main:local\(\d+\.\d+\.\d+\.\d+\)/;
  like $result, qr/^$local:repo:repo:text-1$/;

  $result
});

$subs->example(-1, 'test', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-2, 'test', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

ok 1 and done_testing;
