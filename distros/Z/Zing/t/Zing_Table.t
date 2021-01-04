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

Zing::Table

=cut

=tagline

Entity Lookup Table

=cut

=abstract

Entity Lookup Table Construct

=cut

=includes

method: count
method: drop
method: fetch
method: first
method: get
method: head
method: index
method: last
method: next
method: prev
method: renew
method: reset
method: set
method: tail
method: term

=cut

=synopsis

  use Zing::Table;

  my $table = Zing::Table->new(name => 'users');

  # my $domain = $table->set('unique-id');

=cut

=libraries

Zing::Types

=cut

=inherits

Zing::Channel

=cut

=attributes

position: rw, opt, Maybe[Int]
type: ro, opt, TableType

=cut

=description

This package provides an index and lookup-table for L<Zing::Repo> derived data
structures which provides the ability to create a collection of repo objects.

=cut

=method count

The count method returns the number of L<Zing::Repo> objects in the table.

=signature count

count() : Int

=example-1 count

  # given: synopsis

  $table->count;

=example-2 count

  # given: synopsis

  $table->set('user-12345');

  $table->count;

=cut

=method drop

The drop method returns truthy if the table has been destroyed. This operation
does not cascade.

=signature drop

drop() : Int

=example-1 drop

  # given: synopsis

  $table->drop;

=cut

=method fetch

The fetch method returns the next C<n> L<Zing::Repo> objects from the table.

=signature fetch

fetch(Int $size = 1) : ArrayRef[Repo]

=example-1 fetch

  # given: synopsis

  $table->fetch;

=example-2 fetch

  # given: synopsis

  $table->set('user-12345');
  $table->set('user-12346');
  $table->set('user-12347');

  $table->fetch(5);

=cut

=method first

The first method returns the first L<Zing::Repo> object created in the table.

=signature first

first() : Maybe[Repo]

=example-1 first

  # given: synopsis

  $table->first;

=cut

=method get

The get method returns the L<Zing::Repo> associated with a specific key.

=signature get

get(Str $key) : Maybe[Repo]

=example-1 get

  # given: synopsis

  $table->get('user-12345');

=cut

=method head

The head method returns the first L<Zing::Repo> object created in the table.

=signature head

head() : Maybe[Repo]

=example-1 head

  # given: synopsis

  $table->head;

=cut

=method index

The index method returns the L<Zing::Repo> object at the position (index) specified.

=signature index

index(Int $position) : Maybe[Repo]

=example-1 index

  # given: synopsis

  $table->index(0);

=cut

=method last

The last method returns the last L<Zing::Repo> object created in the table.

=signature last

last() : Maybe[Repo]

=example-1 last

  # given: synopsis

  $table->last;

=cut

=method next

The next method returns the next L<Zing::Repo> object created in the table.

=signature next

next() : Maybe[Repo]

=example-1 next

  # given: synopsis

  $table->next;

=example-2 next

  # given: synopsis

  $table->position(undef);

  $table->prev;
  $table->prev;
  $table->next;

=example-3 next

  # given: synopsis

  $table->position($table->size);

  $table->prev;
  $table->next;
  $table->prev;

=cut

=method prev

The prev method returns the previous L<Zing::Repo> object created in the table.

=signature prev

prev() : Maybe[Repo]

=example-1 prev

  # given: synopsis

  $table->prev;

=example-2 prev

  # given: synopsis

  $table->next;
  $table->next;
  $table->prev;

=example-3 prev

  # given: synopsis

  $table->position($table->size);

  $table->next;
  $table->next;
  $table->prev;

=example-4 prev

  # given: synopsis

  $table->position(undef);

  $table->next;
  $table->prev;
  $table->next;

=cut

=method renew

The renew method returns truthy if it resets the internal cursor, otherwise falsy.

=signature renew

renew() : Int

=example-1 renew

  # given: synopsis

  $table->renew;

=cut

=method reset

The reset method always reset the internal cursor and return truthy.

=signature reset

reset() : Int

=example-1 reset

  # given: synopsis

  $table->reset;

=cut

=method set

The set method creates a L<Zing::Repo> association with a specific key in the
table. The key should be unique. Adding the same key will result in duplicate
entries.

=signature set

set(Str $key) : Repo

=example-1 set

  # given: synopsis

  $table->set('user-12345');

=cut

=method tail

The tail method returns the last L<Zing::Repo> object created in the table.

=signature tail

tail() : Maybe[Repo]

=example-1 tail

  # given: synopsis

  $table->tail;

=cut

=method term

The term method returns the name of the table.

=signature term

term() : Str

=example-1 term

  # given: synopsis

  $table->term;

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'count', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);
  is $result, 0;

  $result
});

$subs->example(-2, 'count', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 1;

  $result
});

$subs->example(-1, 'drop', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'fetch', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

$subs->example(-2, 'fetch', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is @$result, 3;
  is $result->[0]->name, 'user-12345';
  is $result->[1]->name, 'user-12346';
  is $result->[2]->name, 'user-12347';

  $result
});

$subs->example(-1, 'first', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Zing::Domain');
  is $result->name, 'user-12345';

  $result
});

$subs->example(-1, 'get', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Zing::Domain');
  is $result->name, 'user-12345';

  $result
});

$subs->example(-1, 'head', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Zing::Domain');
  is $result->name, 'user-12345';

  $result
});

$subs->example(-1, 'index', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Zing::Domain');
  is $result->name, 'user-12345';

  $result
});

$subs->example(-1, 'last', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Zing::Domain');
  is $result->name, 'user-12347';

  $result
});

$subs->example(-1, 'next', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Zing::Domain');
  is $result->name, 'user-12345';

  $result
});

$subs->example(-2, 'next', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Zing::Domain');
  is $result->name, 'user-12345';

  $result
});

$subs->example(-3, 'next', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Zing::Domain');
  is $result->name, 'user-12347';

  $result
});

$subs->example(-1, 'prev', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-2, 'prev', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Zing::Domain');
  is $result->name, 'user-12345';

  $result
});

$subs->example(-3, 'prev', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Zing::Domain');
  is $result->name, 'user-12347';

  $result
});

$subs->example(-4, 'prev', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Zing::Domain');
  is $result->name, 'user-12345';

  $result
});

$subs->example(-1, 'renew', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-1, 'reset', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'set', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Zing::Domain');
  is $result->name, 'user-12345';

  $result
});

$subs->example(-1, 'tail', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Zing::Domain');
  is $result->name, 'user-12345';

  $result
});

$subs->example(-1, 'term', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

ok 1 and done_testing;
