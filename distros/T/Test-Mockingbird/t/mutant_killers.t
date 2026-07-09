#!/usr/bin/env perl
# Mutant-killer tests for lib/Test/Mockingbird/Async.pm
# Targets all survivors from xt/mutant_20260708_134720.t
#
# Mutations addressed:
#   NUM_BOUNDARY_211_21_!=   HIGH   line 211  @queue == 1  ->  @queue != 1
#   BOOL_NEGATE_213_3        MEDIUM line 213  ternary condition negated
#   BOOL_NEGATE_258_3        MEDIUM line 258  return $future  ->  return !$future
#   BOOL_NEGATE_335_3        MEDIUM line 335  return $future  ->  return !$future
#   BOOL_NEGATE_341_2        MEDIUM line 341  return sub{...} ->  return !sub{...}
#   RETURN_UNDEF_213_3       LOW    line 213  return undef instead of Future
#   RETURN_UNDEF_258_3       LOW    line 258  return undef instead of $future
#   RETURN_UNDEF_335_3       LOW    line 335  return undef instead of $future
#   RETURN_UNDEF_341_2       LOW    line 341  return undef instead of sub{...}

use strict;
use warnings;

use Test::Most;
use Test::Returns;
use Scalar::Util qw(refaddr);
use Readonly;

use Test::Mockingbird qw(restore_all);

# Gate the entire file on Future being available -- Async.pm needs it.
unless (eval { require Future; 1 }) {
	plan skip_all => 'Future not installed';
}

use Test::Mockingbird::Async qw(
	mock_future_sequence
	mock_future_once
	async_spy
);

# ---------------------------------------------------------------------------
# Companion packages -- simple stubs consumed by each test group.
# Defined here so they are known to the parser before any subtest runs.
# ---------------------------------------------------------------------------

{ package MK::Seq1;    sub fn    { 'orig_1'         } }
{ package MK::Seq2;    sub fn    { 'orig_2'         } }
{ package MK::Seq3;    sub fn    { 'orig_3'         } }
{ package MK::SeqPl;   sub fn    { 'orig_plain'     } }
{ package MK::SeqFut;  sub fn    { 'orig_fut'       } }
{ package MK::Once;    sub ping  { 'orig_ping'      } }
{ package MK::Spy1;    sub fetch { Future->done('orig_fetch')  } }
{ package MK::Spy2;    sub op    { Future->done('orig_op')     } }

# ---------------------------------------------------------------------------
# Constants -- eliminate magic numbers and strings.
# ---------------------------------------------------------------------------

Readonly::Scalar my $ITEM_SINGLE  => 42;
Readonly::Scalar my $ITEM_FIRST   => 10;
Readonly::Scalar my $ITEM_SECOND  => 20;
Readonly::Array  my @ITEMS_THREE  => (1, 2, 3);
Readonly::Scalar my $ITEM_PLAIN   => 99;
Readonly::Scalar my $MOCKED_VAL   => 'mocked_val';
Readonly::Scalar my $ORIG_FETCH   => 'orig_fetch';
Readonly::Scalar my $ORIG_PING    => 'orig_ping';

# ===========================================================================
# GROUP 1 -- NUM_BOUNDARY_211_21_!=  (line 211, HIGH)
#
# Source:   my $item = @queue == 1 ? $queue[0] : shift @queue;
# Mutation: @queue == 1  ->  @queue != 1
#
# Original logic:
#   @queue == 1  => peek [0] (repeat the last element forever)
#   @queue != 1  => shift     (advance to next element)
#
# Mutant logic (inverted):
#   @queue == 1  => shift     (consumes the last element; queue empty on next call)
#   @queue != 1  => peek [0]  (never advances; same element returned every time)
#
# Kill strategy A (queue of 1): call twice; both calls must return the same
#   value.  With mutant, the first call shifts the only element; the second
#   call gets undef.
# Kill strategy B (queue of 2): call three times; the second call must return
#   a different value from the first.  With mutant, peek never advances so
#   every call returns item 1 -- the second call would still be 10, not 20.
# Kill strategy C (queue of 3): verify the full transition sequence and final
#   repeat; the mutant collapses all calls to the first element.
# ===========================================================================

subtest 'NUM_BOUNDARY(211): single-item sequence repeats on every subsequent call' => sub {
	# Strategy A: one item must be repeated indefinitely (peek, never shift).
	# Mutant shifts on first call -> queue empty -> second call returns undef.
	mock_future_sequence('MK::Seq1::fn', $ITEM_SINGLE);

	my $v1 = MK::Seq1::fn()->get;
	my $v2 = MK::Seq1::fn()->get;
	my $v3 = MK::Seq1::fn()->get;

	is $v1, $ITEM_SINGLE, 'call 1: single-item queue returns the item';
	is $v2, $ITEM_SINGLE, 'call 2: single-item queue still returns same item (peek)';
	is $v3, $ITEM_SINGLE, 'call 3: single-item queue continues to repeat';

	diag "v1=$v1 v2=$v2 v3=$v3" if $ENV{TEST_VERBOSE};

	restore_all();
};

subtest 'NUM_BOUNDARY(211): two-item sequence advances on first call then repeats last' => sub {
	# Strategy B: two-item queue.
	#   Call 1: @queue==2 -> shift -> item1, queue becomes [item2]
	#   Call 2: @queue==1 -> peek  -> item2 (the new last element)
	#   Call 3: @queue==1 -> peek  -> item2 (repeats)
	# Mutant (!=):
	#   Call 1: @queue!=1 (true, 2!=1) -> peek -> item1 (no advance)
	#   Call 2: @queue!=1 (still 2)    -> peek -> item1 (WRONG)
	mock_future_sequence('MK::Seq2::fn', $ITEM_FIRST, $ITEM_SECOND);

	my $v1 = MK::Seq2::fn()->get;
	my $v2 = MK::Seq2::fn()->get;
	my $v3 = MK::Seq2::fn()->get;

	is $v1, $ITEM_FIRST,  'call 1 returns item 1 (shifted from 2-element queue)';
	is $v2, $ITEM_SECOND, 'call 2 returns item 2 (peeked from 1-element queue)';
	is $v3, $ITEM_SECOND, 'call 3 repeats item 2';

	diag "v1=$v1 v2=$v2 v3=$v3" if $ENV{TEST_VERBOSE};

	restore_all();
};

subtest 'NUM_BOUNDARY(211): three-item sequence advances through all items then repeats last' => sub {
	# Strategy C: full transition sequence.
	# Original:  shift, shift, peek, peek ...
	# Mutant:    peek, peek, peek, ... (stuck on item 1)
	mock_future_sequence('MK::Seq3::fn', @ITEMS_THREE);

	is MK::Seq3::fn()->get, 1, 'call 1 returns item 1';
	is MK::Seq3::fn()->get, 2, 'call 2 returns item 2 (advanced)';
	is MK::Seq3::fn()->get, 3, 'call 3 returns item 3 (advanced to last)';
	is MK::Seq3::fn()->get, 3, 'call 4 repeats item 3 (last element stays)';

	restore_all();
};

# ===========================================================================
# GROUP 2 -- BOOL_NEGATE_213_3 / RETURN_UNDEF_213_3  (line 213, MEDIUM/LOW)
#
# Source:   return (ref $item && $item->isa('Future')) ? $item : Future->done($item);
# Mutation (BOOL_NEGATE): condition negated ->
#           return !(ref $item && $item->isa('Future')) ? $item : Future->done($item)
#   which means:
#     when $item IS     a Future: takes the ELSE arm -> double-wraps as Future->done($item)
#     when $item is NOT a Future: takes the THEN arm -> returns $item directly (no wrap)
# Mutation (RETURN_UNDEF): returns undef instead of a Future
#
# Kill strategy (plain value):
#   Pass a plain scalar in the sequence.  The return must be a Future wrapping
#   that value, not the plain scalar itself.  Mutant returns plain 99 -> isa_ok fails.
#
# Kill strategy (pre-built Future):
#   Pass a pre-constructed Future in the sequence.  The return must be that
#   exact Future (identity check via refaddr).  Mutant wraps it in
#   Future->done($future) -> refaddr differs -> is() on ->get also fails.
# ===========================================================================

subtest 'BOOL_NEGATE(213) + RETURN_UNDEF(213): plain scalar is wrapped in Future->done' => sub {
	# Mutant BOOL_NEGATE: negated condition passes plain scalar through directly.
	# Mutant RETURN_UNDEF: returns undef.
	# Both killed by checking the return is a Future that resolves to the plain value.
	mock_future_sequence('MK::SeqPl::fn', $ITEM_PLAIN);

	my $f = MK::SeqPl::fn();

	ok defined($f), 'return is defined (kills RETURN_UNDEF: undef returned)';
	isa_ok $f, 'Future', 'return is a Future (kills BOOL_NEGATE: plain 99 returned)';
	is $f->get, $ITEM_PLAIN, 'Future resolves to the original plain value';

	diag "got ref=" . ref($f) if $ENV{TEST_VERBOSE};

	restore_all();
};

subtest 'BOOL_NEGATE(213): pre-built Future passes through unchanged (identity)' => sub {
	# When $item is already a Future the original code must return it by identity.
	# Mutant BOOL_NEGATE: inverts condition -> double-wraps the Future in
	#   Future->done($item).  The double-wrapped object is a NEW Future whose
	#   ->get returns the inner Future, not 'pre_built_value'.
	my $pre = Future->done('pre_built_value');
	mock_future_sequence('MK::SeqFut::fn', $pre);

	my $f = MK::SeqFut::fn();

	# Identity: same object reference
	is refaddr($f), refaddr($pre),
		'pre-built Future returned by identity (kills BOOL_NEGATE: new wrapper returned)';

	# Value: resolved value is the string, not a nested Future object
	is $f->get, 'pre_built_value',
		'Future resolves to original value (kills BOOL_NEGATE: ->get would return $pre obj)';

	diag "returned refaddr=" . refaddr($f) . " pre refaddr=" . refaddr($pre)
		if $ENV{TEST_VERBOSE};

	restore_all();
};

# ===========================================================================
# GROUP 3 -- BOOL_NEGATE_258_3 / RETURN_UNDEF_258_3  (line 258, MEDIUM/LOW)
#
# Source (inside the wrapper installed by mock_future_once):
#   my $future = Future->done(@values);
#   Test::Mockingbird::unmock($package, $method);
#   return $future;                   # <-- line 258
#
# Mutation (BOOL_NEGATE): return !$future  -> returns 0 (falsy) for a truthy Future
# Mutation (RETURN_UNDEF): returns undef
#
# Kill strategy: invoke the mocked method and assert that:
#   1. the return is defined
#   2. the return isa Future
#   3. ->get resolves to the declared value(s)
#   4. the original is restored on the second call (verifying unmock was not skipped)
# ===========================================================================

subtest 'BOOL_NEGATE(258) + RETURN_UNDEF(258): mock_future_once call must return a Future' => sub {
	mock_future_once('MK::Once::ping', $MOCKED_VAL);

	my $f = MK::Once::ping();

	ok defined($f), 'return is defined (kills RETURN_UNDEF: undef)';
	isa_ok $f, 'Future', 'return isa Future (kills BOOL_NEGATE: !$future = 0)';
	is $f->get, $MOCKED_VAL, 'Future resolves to the mocked value';

	# Second call after once: original must be restored.
	is MK::Once::ping(), $ORIG_PING, 'second call returns original (mock_future_once is one-shot)';

	diag "f=" . (defined $f ? ref($f) : 'undef') if $ENV{TEST_VERBOSE};

	restore_all();
};

subtest 'BOOL_NEGATE(258): mock_future_once with multi-value list' => sub {
	# Exercises the @values splice into Future->done() and validates the resolution.
	mock_future_once('MK::Once::ping', 'alpha', 'beta', 'gamma');

	my $f = MK::Once::ping();

	isa_ok $f, 'Future', 'multi-value once returns a Future';
	my @vals = $f->get;
	is_deeply \@vals, ['alpha', 'beta', 'gamma'],
		'Future resolves to the complete multi-value list';

	restore_all();
};

subtest 'RETURN_UNDEF(258): mock_future_once with no values still returns a Future' => sub {
	# Future->done() with zero values: resolved but ->get returns undef.
	mock_future_once('MK::Once::ping');

	my $f = MK::Once::ping();

	ok defined($f), 'zero-value once: return is defined';
	isa_ok $f, 'Future', 'zero-value once: return isa Future';

	my $val = $f->get;
	ok !defined($val), 'zero-value once: resolved value is undef';

	restore_all();
};

# ===========================================================================
# GROUP 4 -- BOOL_NEGATE_335_3 / RETURN_UNDEF_335_3  (line 335, MEDIUM/LOW)
#
# Source (async_spy inner wrapper):
#   my $future = $orig->(@call_args);
#   push @calls, { args => [...], future => $future };
#   Test::Mockingbird::_record_call($full_method);
#   return $future;                   # <-- line 335
#
# Mutation (BOOL_NEGATE): return !$future  -> caller receives 0 instead of the Future
# Mutation (RETURN_UNDEF): caller receives undef
#
# Kill strategy: call through the spy and assert the RETURN VALUE of that call
#   is a live Future.  Also verify the returned object is the same as the one
#   captured in the call record (ensuring no copy or re-wrapping occurred).
# ===========================================================================

subtest 'BOOL_NEGATE(335) + RETURN_UNDEF(335): spy wrapper must return the original Future' => sub {
	my $spy = async_spy('MK::Spy1::fetch');

	my $ret = MK::Spy1::fetch('arg1');   # goes through the spy wrapper

	ok defined($ret), 'spy-wrapped call returns defined value (kills RETURN_UNDEF)';
	isa_ok $ret, 'Future',
		'spy-wrapped call returns a Future (kills BOOL_NEGATE: returns !$future = 0)';
	is $ret->get, $ORIG_FETCH,
		'spy-wrapped Future resolves to the original method return value';

	# Cross-check: the future captured in the call record is the SAME object
	# that was returned to the caller.
	my @calls = $spy->();
	is scalar @calls, 1, 'one call recorded';
	is refaddr($ret), refaddr($calls[0]{future}),
		'caller receives same Future object recorded in call log (refaddr match)';

	diag "ret=" . (defined $ret ? ref($ret) : 'undef') if $ENV{TEST_VERBOSE};

	restore_all();
};

subtest 'BOOL_NEGATE(335): return value propagates through multiple spy calls' => sub {
	# Verify that EACH call returns a distinct, valid Future (not a cached one).
	my $call_n = 0;
	{ no warnings 'redefine';
	  *MK::Spy1::fetch = sub { Future->done("fetch_" . ++$call_n) };
	}

	my $spy = async_spy('MK::Spy1::fetch');

	my $f1 = MK::Spy1::fetch('x');
	my $f2 = MK::Spy1::fetch('y');

	isa_ok $f1, 'Future', 'first call: return isa Future';
	isa_ok $f2, 'Future', 'second call: return isa Future';
	is $f1->get, 'fetch_1', 'first Future resolves correctly';
	is $f2->get, 'fetch_2', 'second Future resolves correctly';

	# Both futures must be distinct objects.
	isnt refaddr($f1), refaddr($f2), 'each call produces a distinct Future object';

	restore_all();
};

# ===========================================================================
# GROUP 5 -- BOOL_NEGATE_341_2 / RETURN_UNDEF_341_2  (line 341, MEDIUM/LOW)
#
# Source:   return sub { @calls };   # <-- line 341
#
# Mutation (BOOL_NEGATE): return !sub { @calls }
#   Since a coderef is always truthy, !coderef = '' (empty string).
# Mutation (RETURN_UNDEF): return undef
#
# Kill strategy: assert that the value returned by async_spy() is:
#   1. defined
#   2. a CODE reference
#   3. callable, and when called returns the captured call records
# ===========================================================================

subtest 'BOOL_NEGATE(341) + RETURN_UNDEF(341): async_spy must return a coderef collector' => sub {
	my $collector = async_spy('MK::Spy2::op');

	ok defined($collector), 'async_spy return is defined (kills RETURN_UNDEF: undef)';
	is ref($collector), 'CODE',
		'async_spy return is a CODE ref (kills BOOL_NEGATE: !sub{}="" not CODE)';

	# Validate the returns schema with Test::Returns.
	returns_is($collector, { type => 'coderef' }, 'async_spy return satisfies coderef schema');

	MK::Spy2::op('p', 'q');
	MK::Spy2::op('r');

	my @calls = $collector->();
	is scalar @calls, 2, 'collector reports two captured calls';

	is_deeply $calls[0]{args}, ['MK::Spy2::op', 'p', 'q'],
		'first call args recorded correctly';
	is_deeply $calls[1]{args}, ['MK::Spy2::op', 'r'],
		'second call args recorded correctly';

	isa_ok $calls[0]{future}, 'Future', 'first call: future field is a Future';
	isa_ok $calls[1]{future}, 'Future', 'second call: future field is a Future';

	restore_all();
};

subtest 'RETURN_UNDEF(341): async_spy collector is callable on zero calls' => sub {
	# Edge: collector must still be a valid coderef even before any calls.
	my $collector = async_spy('MK::Spy2::op');

	is ref($collector), 'CODE', 'collector is a CODE ref before any calls';

	my @calls = $collector->();
	is scalar @calls, 0, 'empty collector returns no calls';

	restore_all();
};

done_testing();
