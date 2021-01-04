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

Zing::Lookup

=cut

=tagline

Domain Lookup Table

=cut

=abstract

Domain Lookup Table Construct

=cut

=includes

method: cursor
method: del
method: drop
method: get
method: set
method: savepoint

=cut

=synopsis

  use Zing::Lookup;

  my $lookup = Zing::Lookup->new(name => 'users');

  # my $domain = $lookup->set('unique-id');

=cut

=libraries

Zing::Types

=cut

=inherits

Zing::Domain

=cut

=description

This package provides an index and lookup-table for L<Zing::Domain> data
structures which provides the ability to create a collection of domains with
full history of state changes.

=cut

=method cursor

The cursor method returns a L<Zing::Cursor> object which provides the ability
to page-through and traverse the lookup dataset forwards and backwards.

=signature cursor

cursor() : Cursor

=example-1 cursor

  # given: synopsis

  $lookup->cursor;

=method del

The del method deletes the L<Zing::Domain> associated with a specific key.

=signature del

del(Str $key) : Lookup

=example-1 del

  # given: synopsis

  $lookup->del('user-12345');

=example-2 del

  # given: synopsis

  $lookup->set('user-12345', 'me@example.com');

  $lookup->del('user-12345');

=method drop

The drop method returns truthy if the lookup has been destroyed. This operation
does not cascade.

=signature drop

drop() : Int

=example-1 drop

  # given: synopsis

  $lookup->set('user-12345', 'me@example.com');

  $lookup->drop;

=example-2 drop

  # given: synopsis

  $lookup->set('user-12345', 'me@example.com');

  $lookup->savepoint->send;

  $lookup->drop;

=method get

The get method return the L<Zing::Domain> associated with a specific key.

=signature get

get(Str $key) : Maybe[Domain]

=example-1 get

  # given: synopsis

  $lookup->get('user-12345');

=example-2 get

  # given: synopsis

  $lookup->set('user-12345')->set(email => 'me@example.com');

  $lookup->get('user-12345');

=method set

The set method creates a L<Zing::Domain> association with a specific key in the
lookup. The key must be unique or will overwrite any existing data.

=signature set

set(Str $key) : Domain

=example-1 set

  # given: synopsis

  $lookup->del('user-12345');

  $lookup->set('user-12345');

=method savepoint

The savepoint method returns a L<Zing::Savepoint> object which provides the
ability to save and restore large indices (lookup states). If a lookup has an
associated savepoint it will be loaded automatically on object construction.

=signature savepoint

savepoint() : Savepoint

=example-1 savepoint

  # given: synopsis

  $lookup->savepoint;

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'cursor', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'del', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok !exists $result->state->{$result->hash('user-12345')};

  $result
});

$subs->example(-2, 'del', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok !exists $result->state->{$result->hash('user-12345')};

  $result
});

$subs->example(-1, 'drop', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  my $lookup = Zing::Lookup->new(name => 'users');
  ok !%{$lookup->state};

  $result
});

$subs->example(-2, 'drop', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  my $lookup = Zing::Lookup->new(name => 'users');
  ok !%{$lookup->state};
  ok !$lookup->savepoint->test;

  $result
});

$subs->example(-1, 'get', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-2, 'get', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Zing::Domain');
  is $result->get('email'), 'me@example.com';

  $result
});

$subs->example(-1, 'set', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Zing::Domain');

  $result
});

$subs->example(-1, 'savepoint', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

ok 1 and done_testing;
