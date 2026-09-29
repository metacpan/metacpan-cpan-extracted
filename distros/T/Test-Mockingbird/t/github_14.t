#!/usr/bin/env perl

# Regression tests for GitHub issue #14: mocking a method that a class only
# inherits must not break it once the mock is removed, and call-through
# wrappers (spy, before, after, around) must reach the inherited method.

use strict;
use warnings;

use Test::Most;

use Test::Mockingbird;

{
	package My::Base;
	sub hello { 'base' }
	sub args  { shift; join ',', @_ }

	package My::Derived;
	our @ISA = ('My::Base');
	our $hello = 'pkg var';    # non-CODE slot sharing the method's GV

	package My::Grandchild;
	our @ISA = ('My::Derived');
}

subtest 'every way of removing a mock restores the inherited method' => sub {
	for my $case (
		[ unmock      => sub { unmock 'My::Derived::hello' } ],
		[ restore     => sub { restore 'My::Derived::hello' } ],
		[ restore_all => sub { restore_all() } ],
		[ 'restore_all($pkg)' => sub { restore_all('My::Derived') } ],
	) {
		my ($name, $remove) = @$case;
		mock 'My::Derived::hello' => sub { 'mocked' };
		is(My::Derived->hello, 'mocked', "$name: mock active");
		$remove->();
		is(My::Derived->hello, 'base', "$name: inherited method works after removal");
	}

	{
		my $g = mock_scoped('My::Derived::hello' => sub { 'scoped' });
		is(My::Derived->hello, 'scoped', 'mock_scoped: mock active');
	}
	is(My::Derived->hello, 'base', 'mock_scoped: inherited method works after guard');
};

subtest 'every way of installing a layer restores the inherited method' => sub {
	for my $case (
		[ mock_return => sub { mock_return 'My::Derived::hello' => 'r' } ],
		[ mock_once   => sub { mock_once 'My::Derived::hello' => sub { 'o' } } ],
		[ spy         => sub { spy 'My::Derived::hello' } ],
		[ before      => sub { before 'My::Derived::hello' => sub { } } ],
		[ after       => sub { after 'My::Derived::hello' => sub { } } ],
		[ around      => sub { around 'My::Derived::hello' => sub { my $o = shift; $o->(@_) } } ],
		[ inject      => sub { inject 'My::Derived', 'hello', 'i' } ],
	) {
		my ($name, $install) = @$case;
		$install->();
		unmock 'My::Derived::hello';
		is(My::Derived->hello, 'base', "$name: inherited method works after unmock");
	}
};

subtest 'stacked layers on an inherited method unwind correctly' => sub {
	mock 'My::Derived::hello' => sub { 'L1' };
	mock 'My::Derived::hello' => sub { 'L2' };
	is(My::Derived->hello, 'L2', 'top layer active');
	unmock 'My::Derived::hello';
	is(My::Derived->hello, 'L1', 'first layer active after one unmock');
	unmock 'My::Derived::hello';
	is(My::Derived->hello, 'base', 'inherited method after both unmocks');
};

subtest 'removal leaves the GV, its other slots and ->can() correct' => sub {
	mock 'My::Derived::hello' => sub { 'mocked' };
	restore_all();
	ok(exists $My::Derived::{hello}, 'GV still in the stash');
	is($My::Derived::hello, 'pkg var', 'package scalar sharing the GV survives');
	ok(!defined &My::Derived::hello, 'no CODE slot in the derived package');
	is(My::Derived->can('hello'), \&My::Base::hello, '->can() finds the parent method');

	# A failed direct call makes Perl itself leave a stub behind, which would
	# shadow the inherited method, so use a class no other subtest touches.
	{ no strict 'refs'; @{'My::Direct::ISA'} = ('My::Base'); }
	mock 'My::Direct::hello' => sub { 'mocked' };
	restore_all();
	throws_ok { no strict 'refs'; &{'My::Direct::hello'}() }
		qr/Undefined subroutine &My::Direct::hello/,
		'direct function call still dies';
};

subtest 'a class further down the hierarchy is unaffected' => sub {
	mock 'My::Derived::hello' => sub { 'mocked' };
	is(My::Grandchild->hello, 'mocked', 'grandchild sees the mock');
	unmock 'My::Derived::hello';
	is(My::Grandchild->hello, 'base', 'grandchild sees the base method again');
};

subtest 'call-through wrappers reach the inherited method while active' => sub {
	my $spy = spy 'My::Derived::args';
	is(My::Derived->args(1, 2), '1,2', 'spy calls through to parent');
	is(scalar(() = $spy->()), 1, 'spy recorded the call');
	restore_all();

	my @seen;
	before 'My::Derived::hello' => sub { push @seen, 'before' };
	is(My::Derived->hello, 'base', 'before calls through to parent');
	unmock 'My::Derived::hello';

	after 'My::Derived::hello' => sub { push @seen, 'after' };
	is(My::Derived->hello, 'base', 'after calls through to parent');
	unmock 'My::Derived::hello';
	is_deeply(\@seen, [qw(before after)], 'hooks fired');

	around 'My::Derived::hello' => sub { my $orig = shift; '[' . $orig->(@_) . ']' };
	is(My::Derived->hello, '[base]', 'around $orig is the parent method');
	my @list = My::Derived->hello;
	is_deeply(\@list, ['[base]'], 'list context preserved');
	unmock 'My::Derived::hello';
};

subtest 'call-through resolves the parent at call time' => sub {
	spy 'My::Derived::hello';
	mock 'My::Base::hello' => sub { 'mocked base' };
	is(My::Derived->hello, 'mocked base', 'spy on child sees a later mock of the parent');
	restore_all();
	is(My::Derived->hello, 'base', 'both restored');
};

subtest 'call-through on a method defined nowhere dies instead of recursing' => sub {
	spy 'My::Nowhere::ghost';
	throws_ok { My::Nowhere->ghost } qr/Undefined subroutine &My::Nowhere::ghost called/,
		'spy on a missing method dies cleanly';
	restore_all();

	around 'My::Nowhere::ghost' => sub { my $orig = shift; $orig->(@_) };
	throws_ok { My::Nowhere->ghost } qr/Undefined subroutine &My::Nowhere::ghost called/,
		'around on a missing method dies cleanly';
	restore_all();
	ok(!defined &My::Nowhere::ghost, 'still undefined after restore');
	ok(!My::Nowhere->can('ghost'), '->can() is false after restore');
};

subtest 'call-through reaches UNIVERSAL, and UNIVERSAL has no ancestors' => sub {
	{ no strict 'refs'; *{'UNIVERSAL::gh14_probe'} = sub { 'universal' }; }

	spy 'My::Base::gh14_probe';
	is(My::Base->gh14_probe, 'universal', 'inherited UNIVERSAL method is reached');
	restore_all();

	spy 'UNIVERSAL::gh14_missing';
	throws_ok { UNIVERSAL::gh14_missing() } qr/Undefined subroutine &UNIVERSAL::gh14_missing called/,
		'a missing UNIVERSAL method is not looked up in itself';
	restore_all();

	{ no strict 'refs'; delete $UNIVERSAL::{gh14_probe}; }
};

subtest 'a declared-but-undefined stub is put back, not removed' => sub {
	{ no strict 'refs'; eval 'package My::Stubbed; our @ISA = ("My::Base"); sub hello; 1' or die $@; }
	mock 'My::Stubbed::hello' => sub { 'mocked' };
	unmock 'My::Stubbed::hello';
	ok(exists &My::Stubbed::hello,   'forward declaration restored');
	ok(!defined &My::Stubbed::hello, 'still has no body');
};

done_testing();
