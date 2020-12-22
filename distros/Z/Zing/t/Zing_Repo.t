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
method: search
method: term
method: test

=cut

=synopsis

  use Zing::Repo;

  my $repo = Zing::Repo->new(name => 'text');

  # $repo->recv;

=cut

=libraries

Zing::Types

=cut

=attributes

name: ro, req, Str
store: ro, opt, Store

=cut

=description

This package provides a general-purpose data storage abstraction.

=cut

=method drop

The drop method returns truthy if the data was removed from the store.

=signature drop

drop() : Int

=example-1 drop

  # given: synopsis

  $repo->drop('text-1');

=cut

=method search

The search method returns a L<Zing::Search> object based on the current repo or
L<Zing::Repo> derived object.

=signature search

search() : Search

=example-1 search

  # given: synopsis

  my $search = $repo->search;

=cut

=method term

The term method generates a term (safe string) for the datastore.

=signature term

term() : Str

=example-1 term

  # given: synopsis

  my $term = $repo->term;

=cut

=method test

The test method returns truthy if the specific key (or datastore) exists.

=signature test

test() : Int

=example-1 test

  # given: synopsis

  $repo->test;

=example-2 test

  # given: synopsis

  $repo->store->send($repo->term, { test => time });

  $repo->test;

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

$subs->example(-1, 'search', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result->bucket, 'text';
  is $result->handle, 'main';
  is $result->symbol, 'repo';
  is $result->system, 'zing';
  is $result->target, 'global';

  $result
});

$subs->example(-1, 'term', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  my $local = qr/zing:main:/;
  like $result, qr/^zing:main:global:repo:text$/;

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
