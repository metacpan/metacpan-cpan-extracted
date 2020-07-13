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

Shared State Management

=cut

=abstract

Shared State Management Construct

=cut

=includes

method: apply
method: change
method: decr
method: del
method: emit
method: get
method: ignore
method: incr
method: listen
method: pop
method: push
method: set
method: shift
method: state
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

=inherits

Zing::Channel

=cut

=attributes

metadata: ro, opt, HashRef

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

  $domain->change('incr', 'karma', 1);

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

=method emit

The emit method executes any callbacks registered using the L</listen> method
associated with a specific key.

=signature emit

emit(Str $key, HashRef $data) : Object

=example-1 emit

  # given: synopsis

  $domain->emit('email', { val => ['me@example.com'] });

=example-2 emit

  # given: synopsis

  $domain->listen('email', sub { my ($self, $data) = @_; $self->{event} = $data; });

  $domain->emit('email', { val => ['me@example.com'] });

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

=method ignore

The ignore method removes the callback specified by the L</listen>, or all
callbacks associated with a specific key if no specific callback if provided.

=signature ignore

ignore(Str $key, Maybe[CodeRef] $sub) : Any

=example-1 ignore

  # given: synopsis

  $domain->ignore('email');

=example-2 ignore

  # given: synopsis

  my $callback = sub { my ($self, $data) = @_; $self->{event} = $data; };

  $domain->listen('email', $callback);

  $domain->ignore('email', $callback);

=example-3 ignore

  # given: synopsis

  my $callback_1 = sub { my ($self, $data) = @_; $self->{event} = [$data, 2]; };

  $domain->listen('email', $callback_1);

  my $callback_2 = sub { my ($self, $data) = @_; $self->{event} = [$data, 1]; };

  $domain->listen('email', $callback_2);

  $domain->ignore('email', $callback_1);

=example-4 ignore

  # given: synopsis

  my $callback_1 = sub { my ($self, $data) = @_; $self->{event} = [$data, 1]; };

  $domain->listen('email', $callback_1);

  my $callback_2 = sub { my ($self, $data) = @_; $self->{event} = [$data, 2]; };

  $domain->listen('email', $callback_2);

  $domain->ignore('email');

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

=method listen

The listen method registers callbacks associated with a specific key which
will be invoked by the L</emit> method or whenever an event matching the key
specified is received and applied.

=signature listen

listen(Str $key, CodeRef $sub) : Object

=example-1 listen

  # given: synopsis

  $domain->ignore('email');

  $domain->listen('email', sub { my ($self, $data) = @_; $self->{event} = $data; });

=example-2 listen

  # given: synopsis

  $domain->ignore('email');

  my $callback = sub { my ($self, $data) = @_; $self->{event} = $data; };

  $domain->listen('email', $callback);

  $domain->listen('email', $callback);

=example-3 listen

  # given: synopsis

  $domain->ignore('email');

  my $callback_1 = sub { my ($self, $data) = @_; $self->{event} = [$data, 1]; };

  $domain->listen('email', $callback_1);

  my $callback_2 = sub { my ($self, $data) = @_; $self->{event} = [$data, 2]; };

  $domain->listen('email', $callback_2);

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

=method state

The state method returns the raw aggregate data associated with the object.

=signature state

state() : HashRef

=example-1 state

  # given: synopsis

  $domain->state;

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
  is $result->state->{karma}, 1;

  $result
});

$subs->example(-1, 'decr', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result->state->{karma}, 0;

  $result
});

$subs->example(-2, 'decr', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result->state->{karma}, -2;

  $result
});

$subs->example(-1, 'del', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok !exists $result->state->{missing};

  $result
});

$subs->example(-2, 'del', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok !exists $result->state->{email};

  $result
});

$subs->example(-1, 'emit', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok !$result->{event};

  $result
});

$subs->example(-2, 'emit', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result->{event}, { val => ['me@example.com'] };

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

$subs->example(-1, 'ignore', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok !$result->handlers->{email};

  $result
});

$subs->example(-2, 'ignore', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok !$result->handlers->{email};

  $result
});

$subs->example(-3, 'ignore', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->handlers->{email};
  is scalar(@{$result->handlers->{email}}), 1;
  $result->emit('email', { val => [1] });
  is_deeply $result->{event}, [{ val => [1] }, 1];

  $result
});

$subs->example(-4, 'ignore', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok !$result->handlers->{email};

  $result
});

$subs->example(-1, 'incr', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result->state->{karma}, -1;

  $result
});

$subs->example(-2, 'incr', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result->state->{karma}, 4;

  $result
});

$subs->example(-1, 'listen', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->handlers->{email};
  is scalar(@{$result->handlers->{email}}), 1;

  $result
});

$subs->example(-2, 'listen', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->handlers->{email};
  is scalar(@{$result->handlers->{email}}), 1;

  $result
});

$subs->example(-3, 'listen', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->handlers->{email};
  is scalar(@{$result->handlers->{email}}), 2;

  $result
});

$subs->example(-1, 'pop', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is @{$result->state->{history}}, 0;

  $result
});

$subs->example(-1, 'push', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is @{$result->state->{history}}, 1;

  $result
});

$subs->example(-1, 'set', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result->state->{updated}, 1234567890;

  $result
});

$subs->example(-1, 'shift', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is @{$result->state->{history}}, 0;

  $result
});

$subs->example(-1, 'state', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, {
    'email' => 'me@example.com',
    'history' => [],
    'karma' => 4,
    'updated' => 1234567890
  };

  $result
});

$subs->example(-1, 'unshift', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is @{$result->state->{history}}, 1;

  $result
});

ok 1 and done_testing;
