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

Zing::Cursor

=cut

=tagline

Lookup Table Traversal

=abstract

Lookup Table Traversal Construct

=cut

=includes

method: count
method: fetch
method: first
method: last
method: next
method: prev
method: reset

=cut

=synopsis

  use Zing::Lookup;
  use Zing::Cursor;

  my $lookup = Zing::Lookup->new(name => 'users');

  $lookup->set('user-12345')->set(username => 'u12345');
  $lookup->set('user-12346')->set(username => 'u12346');
  $lookup->set('user-12347')->set(username => 'u12347');

  my $cursor = Zing::Cursor->new(lookup => $lookup);

  # $cursor->count;

=cut

=libraries

Zing::Types

=cut

=attributes

position: rw, opt, Maybe[Str]
lookup: ro, req, Lookup

=cut

=description

This package provides a cursor for traversing L<Zing::Lookup> indices and
supports forward and backwards traversal as well as token-based pagination.

=cut

=method count

The count method returns the number of L<Zing::Domain> objects in the lookup
table.

=signature count

count() : Int

=example-1 count

  # given: synopsis

  $cursor->count;

=cut

=method fetch

The fetch method returns the next C<n> L<Zing::Domain> objects from the lookup
table.

=signature fetch

fetch(Int $size = 1) : ArrayRef[Domain]

=example-1 fetch

  # given: synopsis

  $cursor->fetch;

=example-2 fetch

  # given: synopsis

  $cursor->fetch(5);

=cut

=method first

The first method returns the first L<Zing::Domain> object created in the lookup
table.

=signature first

first() : Maybe[Domain]

=example-1 first

  # given: synopsis

  $cursor->first;

=cut

=method last

The last method returns the last L<Zing::Domain> object created in the lookup
table.

=signature last

last() : Maybe[Domain]

=example-1 last

  # given: synopsis

  $cursor->last;

=cut

=method next

The next method returns the next (after the current position) L<Zing::Domain>
object in the lookup table.

=signature next

next() : Maybe[Domain]

=example-1 next

  # given: synopsis

  $cursor->next;

=example-2 next

  # given: synopsis

  $cursor->next;
  $cursor->next;

=cut

=method prev

The prev method returns the prev (before the current position) L<Zing::Domain>
object in the lookup table.

=signature prev

prev() : Maybe[Domain]

=example-1 prev

  # given: synopsis

  $cursor->prev;

=example-2 prev

  # given: synopsis

  $cursor->prev;
  $cursor->prev;

=cut

=method reset

The reset method returns the cursor to its starting position (defined at
construction).

=signature reset

reset() : Cursor

=example-1 reset

  # given: synopsis

  $cursor->prev;
  $cursor->next;
  $cursor->next;

  $cursor->reset;

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'count', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 3;

  $result
});

$subs->example(-1, 'fetch', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is @$result, 1;
  is $result->[0]->state->{username}, 'u12345';

  $result
});

$subs->example(-2, 'fetch', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is @$result, 3;
  is $result->[0]->state->{username}, 'u12345';
  is $result->[1]->state->{username}, 'u12346';
  is $result->[2]->state->{username}, 'u12347';

  $result
});

$subs->example(-1, 'first', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Zing::Domain');
  is $result->state->{username}, 'u12345';

  $result
});

$subs->example(-1, 'last', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Zing::Domain');
  is $result->state->{username}, 'u12347';

  $result
});

$subs->example(-1, 'next', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Zing::Domain');
  is $result->state->{username}, 'u12345';

  $result
});

$subs->example(-2, 'next', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Zing::Domain');
  is $result->state->{username}, 'u12346';

  $result
});

$subs->example(-1, 'prev', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Zing::Domain');
  is $result->state->{username}, 'u12347';

  $result
});

$subs->example(-2, 'prev', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Zing::Domain');
  is $result->state->{username}, 'u12346';

  $result
});

$subs->example(-1, 'reset', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

ok 1 and done_testing;
