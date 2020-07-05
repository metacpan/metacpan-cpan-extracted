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

Zing::Domain

=cut

=tagline

Aggregate Root

=cut

=abstract

Aggregate Root Construct

=cut

=includes

method: apply
method: change
method: data
method: decr
method: del
method: get
method: incr
method: pop
method: push
method: set
method: shift
method: unshift

=cut

=synopsis

  use Zing::Domain;

  my $domain = Zing::Domain->new(name => 'user-1');

  # $domain->recv;

=cut

=libraries

Zing::Types

=cut

=attributes

name: ro, req, Str
channel: ro, opt, Channel
threshold: ro, opt, Str

=cut

=description

This package provides an aggregate abstraction and real-time cross-process
sharable data structure which offers many benefits, not least being able to see
a full history of state changes.

=cut

=method apply

The apply method receives events from the channel and applies the operations.

=signature apply

apply() : Object

=example-1 apply

  # given: synopsis

  $domain->apply;

=cut

=method change

The change method commits an operation (and snapshot) to the channel. This
method is used internally and shouldn't need to be called directly.

=signature change

change(Str $op, Str $key, Any @val) : Object

=example-1 change

  # given: synopsis

  $domain->change('incr', 'karma');

=cut

=method data

The data method returns the raw aggregate data associated with the object.

=signature data

data() : HashRef

=example-1 data

  # given: synopsis

  $domain->data;

=cut

=method decr

The decr method decrements the data associated with a specific key.

=signature decr

decr(Str $key, Int $val = 1) : Object

=example-1 decr

  # given: synopsis

  $domain->decr('karma');

=example-2 decr

  # given: synopsis

  $domain->decr('karma', 2);

=cut

=method del

The del method deletes the data associated with a specific key.

=signature del

del(Str $key) : Object

=example-1 del

  # given: synopsis

  $domain->del('missing');

=example-2 del

  # given: synopsis

  $domain->set('email', 'me@example.com');

  $domain->del('email');

=cut

=method get

The get method return the data associated with a specific key.

=signature get

get(Str $key) : Any

=example-1 get

  # given: synopsis

  $domain->get('email');

=example-2 get

  # given: synopsis

  $domain->set('email', 'me@example.com');

  $domain->get('email');

=cut

=method incr

The incr method increments the data associated with a specific key.

=signature incr

incr(Str $key, Int $val = 1) : Object

=example-1 incr

  # given: synopsis

  $domain->incr('karma');

=example-2 incr

  # given: synopsis

  $domain->incr('karma', 5);

=cut

=method pop

The pop method pops the data off of the stack associated with a specific key.

=signature pop

pop(Str $key) : Object

=example-1 pop

  # given: synopsis

  $domain->pop('history');

=cut

=method push

The push method pushes data onto the stack associated with a specific key.

=signature push

push(Str $key, Any @val) : Object

=example-1 push

  # given: synopsis

  $domain->push('history', { updated => 1234567890 });

=cut

=method set

The set method commits the data associated with a specific key to the channel.

=signature set

set(Str $key, Any $val) : Object

=example-1 set

  # given: synopsis

  $domain->set('updated', 1234567890);

=cut

=method shift

The shift method shifts data off of the stack associated with a specific key.

=signature shift

shift(Str $key) : Object

=example-1 shift

  # given: synopsis

  $domain->shift('history');

=cut

=method unshift

The unshift method unshifts data onto the stack associated with a specific key.

=signature unshift

unshift(Str $key, Any @val) : Object

=example-1 unshift

  # given: synopsis

  $domain->unshift('history', { updated => 1234567890 });

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'apply', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'change', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result->data->{karma}, 1;

  $result
});

$subs->example(-1, 'data', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, {karma => 1};

  $result
});

$subs->example(-1, 'decr', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result->data->{karma}, 0;

  $result
});

$subs->example(-2, 'decr', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result->data->{karma}, -2;

  $result
});

$subs->example(-1, 'del', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok !exists $result->data->{missing};

  $result
});

$subs->example(-2, 'del', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok !exists $result->data->{email};

  $result
});

$subs->example(-1, 'get', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-2, 'get', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'me@example.com';

  $result
});

$subs->example(-1, 'incr', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result->data->{karma}, -1;

  $result
});

$subs->example(-2, 'incr', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result->data->{karma}, 4;

  $result
});

$subs->example(-1, 'pop', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is @{$result->data->{history}}, 0;

  $result
});

$subs->example(-1, 'push', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is @{$result->data->{history}}, 1;

  $result
});

$subs->example(-1, 'set', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result->data->{updated}, 1234567890;

  $result
});

$subs->example(-1, 'shift', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is @{$result->data->{history}}, 0;

  $result
});

$subs->example(-1, 'unshift', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is @{$result->data->{history}}, 1;

  $result
});

ok 1 and done_testing;
