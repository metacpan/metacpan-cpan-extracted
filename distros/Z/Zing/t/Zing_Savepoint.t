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

Zing::Savepoint

=cut

=tagline

Lookup Table Savepoint

=abstract

Lookup Table Savepoint Construct

=cut

=includes

method: capture
method: drop
method: position
method: metadata
method: name
method: repo
method: recv
method: send
method: snapshot
method: test

=cut

=synopsis

  use Zing::Lookup;
  use Zing::Savepoint;

  my $lookup = Zing::Lookup->new(name => 'users');

  $lookup->set('user-12345')->set(username => 'u12345');
  $lookup->set('user-12346')->set(username => 'u12346');
  $lookup->set('user-12347')->set(username => 'u12347');

  my $savepoint = Zing::Savepoint->new(lookup => $lookup);

  # $savepoint->test;

=cut

=libraries

Zing::Types

=cut

=attributes

lookup: ro, req, Lookup

=cut

=description

This package provides a savepoint mechanism for saving and restoring large
L<Zing::Lookup> indices. If a lookup has an associated savepoint it will be
used to build the index on (L<Zing::Lookup>) object construction automatically,
however, creating the savepoint (saving the state of the index) needs to be
done manually.

=cut

=method drop

The drop method removes the persisted savepoint.

=signature drop

drop() : Bool

=example-1 drop

  # given: synopsis

  $savepoint->drop;

=cut

=method capture

The capture method returns the relevant state properties from the lookup.

=signature capture

capture() : HashRef

=example-1 capture

  # given: synopsis

  $savepoint->capture;

=cut

=method position

The position method returns the cached position property for the lookup.

=signature position

position() : Int

=example-1 position

  use Zing::Lookup;
  use Zing::Savepoint;

  my $lookup = Zing::Lookup->new(name => 'users');
  my $savepoint = Zing::Savepoint->new(lookup => $lookup);

  $lookup->drop;
  $savepoint->drop;

  $lookup->set('user-12345')->set(username => 'u12345');
  $lookup->set('user-12346')->set(username => 'u12346');
  $lookup->set('user-12347')->set(username => 'u12347');

  $savepoint->send;
  $savepoint->position;

=cut

=method metadata

The metadata method returns the cached metadata property for the lookup.

=signature metadata

metadata() : HashRef

=example-1 metadata

  # given: synopsis

  $savepoint->metadata;

=cut

=method name

The name method returns the generated savepoint name.

=signature name

name() : Str

=example-1 name

  # given: synopsis

  $savepoint->name;

=cut

=method repo

The repo method returns the L<Zing::KeyVal> object used to manage the
savepoint.

=signature repo

repo() : KeyVal

=example-1 repo

  # given: synopsis

  $savepoint->repo;

=cut

=method recv

The recv method returns the data (if any) associated with the savepoint.

=signature recv

recv() : Any

=example-1 recv

  # given: synopsis

  $savepoint->recv;

=cut

=method send

The send method caches and stores the data from L</capture> as a savepoint and
returns the data.

=signature send

send() : HashRef

=example-1 send

  # given: synopsis

  $savepoint->send;

=cut

=method snapshot

The snapshot method returns the cached snapshot property for the lookup.

=signature snapshot

snapshot() : HashRef

=example-1 snapshot

  # given: synopsis

  $savepoint->snapshot;

=cut

=method test

The test method checks whether the savepoint exists and returns truthy or falsy.

=signature test

test() : Bool

=example-1 test

  # given: synopsis

  $savepoint->repo->drop('state');

  $savepoint->test;

=example-2 test

  # given: synopsis

  $savepoint->send;

  $savepoint->test;

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

$subs->example(-1, 'capture', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok exists $result->{position};
  ok exists $result->{metadata};
  ok exists $result->{snapshot};

  $result
});

$subs->example(-1, 'position', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 5;

  $result
});

$subs->example(-1, 'metadata', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok exists $result->{head};
  ok exists $result->{tail};

  $result
});

$subs->example(-1, 'name', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'users#savepoint';

  $result
});

$subs->example(-1, 'repo', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Zing::KeyVal');

  $result
});

$subs->example(-1, 'recv', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok exists $result->{position};
  ok exists $result->{metadata};
  ok exists $result->{snapshot};

  $result
});

$subs->example(-1, 'send', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok exists $result->{position};
  ok exists $result->{metadata};
  ok exists $result->{snapshot};

  $result
});

$subs->example(-1, 'snapshot', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok !!%{$result};

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
