#!/usr/bin/env perl

use strict;
use warnings;

use lib 'lib';

use Test::Most;
use Test::Mockingbird;
use Test::Mockingbird::DeepMock qw(deep_mock);
use Test::Mockingbird::TimeTravel qw(
	now
	freeze_time
	travel_to
	advance_time
	rewind_time
	with_frozen_time
);
# restore_all is imported from Test::Mockingbird via @EXPORT.
# TimeTravel's restore_all is called explicitly as
# Test::Mockingbird::TimeTravel::restore_all() throughout this file.

# ----------------------------------------------------------------------
# EXTENDED TEST SUITE
#
# Targets branches, conditions, and functions that remain uncovered
# after unit.t, function.t, integration.t, edge-cases.t, and
# mock_scoped_multi.t.  Organised into named sections; each subtest
# is labelled with the line(s) of Mockingbird.pm / DeepMock.pm /
# TimeTravel.pm it is designed to hit.
# ----------------------------------------------------------------------

# ===========================================================================
# 1. diagnose_mocks_pretty
#    Never called in any prior test file -- zero coverage.
# ===========================================================================

subtest 'diagnose_mocks_pretty: empty state returns empty string' => sub {
	# When nothing is mocked the loop body never executes, so the return
	# value should be an empty string (joined from an empty list).
	my $out = diagnose_mocks_pretty();
	is $out, '', 'empty state returns empty string';
};

subtest 'diagnose_mocks_pretty: format with one active mock' => sub {
	{
		package DMP::One;
		sub a { 1 }
	}

	mock_return 'DMP::One::a' => 99;

	my $out = diagnose_mocks_pretty();

	# The output must contain the fully qualified name, depth, type, and
	# the installed_at field.  We do not hard-code exact line numbers.
	like $out, qr/DMP::One::a:/,       'method name present';
	like $out, qr/depth: 1/,           'depth present';
	like $out, qr/original_existed: 1/, 'original_existed present';
	like $out, qr/type: mock_return/,   'type label present';
	like $out, qr/installed_at:/,       'installed_at field present';

	restore_all();
};

subtest 'diagnose_mocks_pretty: multiple methods sorted alphabetically' => sub {
	{
		package DMP::Multi;
		sub b { 1 }
		sub a { 2 }
	}

	mock_return    'DMP::Multi::a' => 10;
	mock_exception 'DMP::Multi::b' => 'boom';

	my $out = diagnose_mocks_pretty();

	# Both methods must appear; sorted order means a before b
	my $pos_a = index $out, 'DMP::Multi::a';
	my $pos_b = index $out, 'DMP::Multi::b';
	ok $pos_a >= 0, 'DMP::Multi::a appears in output';
	ok $pos_b >= 0, 'DMP::Multi::b appears in output';
	ok $pos_a < $pos_b, 'methods are sorted (a before b)';

	restore_all();
};

subtest 'diagnose_mocks_pretty: cleared after restore_all' => sub {
	{
		package DMP::Clear;
		sub x { 1 }
	}

	# Ensure clean state before installing the mock for this subtest
	restore_all();

	mock_return 'DMP::Clear::x' => 5;
	restore_all();

	my $out = diagnose_mocks_pretty();
	is $out, '', 'output empty after restore_all';
};

# ===========================================================================
# 2. mock_once -- wantarray branches
#    Line 966: return wantarray ? @result : $result[0]
#    Prior tests only called mock_once in void/scalar context.
# ===========================================================================

subtest 'mock_once: scalar context return value' => sub {
	{
		package MO::Ctx;
		sub fn { ('a', 'b', 'c') }
	}

	mock_once 'MO::Ctx::fn' => sub { (10, 20, 30) };

	# Scalar context: mock_once must return $result[0]
	my $val = MO::Ctx::fn();
	is $val, 10, 'mock_once scalar context returns first element';

	restore_all();
};

subtest 'mock_once: list context return value' => sub {
	{
		package MO::Ctx;
		# fn already declared above
	}

	mock_once 'MO::Ctx::fn' => sub { (10, 20, 30) };

	# List context: mock_once must return the full list
	my @vals = MO::Ctx::fn();
	is_deeply \@vals, [10, 20, 30], 'mock_once list context returns full list';

	restore_all();
};

subtest 'mock_once: original restored and callable after one use' => sub {
	{
		package MO::Restore;
		sub fn { ('x', 'y') }
	}

	mock_once 'MO::Restore::fn' => sub { (1, 2) };
	my @first  = MO::Restore::fn();    # triggers unmock internally
	my @second = MO::Restore::fn();    # original

	is_deeply \@first,  [1, 2],   'first call: mock result';
	is_deeply \@second, ['x','y'], 'second call: original result';
};

# ===========================================================================
# 3. mock_scoped -- croak paths
#    Line 467: non-CODE in multi shorthand
#    Line 479: non-CODE in multi longhand
#    Line 485: unrecognised argument form
# ===========================================================================

subtest 'mock_scoped: croaks on unrecognised argument form' => sub {
	# Three args where arg2 is not a plain string and not CODE -- no arm matches
	dies_ok {
		mock_scoped('Pkg::m1', 'Pkg::m2', 'Pkg::m3');
	} 'mock_scoped croaks on unrecognised form';

	like $@, qr/unrecognised argument form/, 'error message correct';
};

subtest 'mock_scoped: croaks when multi shorthand pair has non-CODE value' => sub {
	{
		package MS::Croak;
		sub fn { 1 }
	}

	# Even arg count, first arg has ::, but second is not a CODE ref
	dies_ok {
		mock_scoped('MS::Croak::fn', 'not_a_coderef',
		            'MS::Croak::fn', sub { 1 });
	} 'multi shorthand croaks when value is not CODE';

	restore_all();
};

subtest 'mock_scoped: croaks when multi longhand pair has non-CODE value' => sub {
	{
		package MS::CroakL;
		sub fn { 1 }
		sub gn { 2 }
	}

	# Odd arg count (package + pairs), but second element of a pair is not CODE
	dies_ok {
		mock_scoped('MS::CroakL', fn => 'not_code', gn => sub { 1 });
	} 'multi longhand croaks when value is not CODE';

	restore_all();
};

# ===========================================================================
# 4. inject -- longhand 3-arg form and croak conditions
#    Line 649: if (defined $arg1 && !defined $arg3 ...) -- else branch (longhand)
#    Line 661: croak unless $package && $dependency
# ===========================================================================

subtest 'inject: longhand 3-arg form installs and restores' => sub {
	{
		package Inj::Long;
		sub dep { 'real' }
	}

	# 3-arg form: inject($package, $dep, $mock_obj)
	inject('Inj::Long', 'dep', 'MOCKED');

	is Inj::Long::dep(), 'MOCKED', 'longhand inject active';

	restore_all();
	is Inj::Long::dep(), 'real', 'original restored after restore_all';
};

subtest 'inject: croaks when dependency arg is undef' => sub {
	dies_ok {
		inject('Some::Pkg', undef, 'val');
	} 'inject croaks when dependency is undef';
};

subtest 'inject: croaks when package arg is undef' => sub {
	dies_ok {
		inject(undef, 'dep', 'val');
	} 'inject croaks when package is undef';
};

# ===========================================================================
# 5. unmock -- croak conditions and longhand 2-arg form
#    Line 315: $arg1 =~ /::/ vs not (longhand form)
#    Line 323: croak unless $package && $method
# ===========================================================================

subtest 'unmock: longhand 2-arg form restores correctly' => sub {
	{
		package Um::Long;
		sub fn { 'orig' }
	}

	mock 'Um::Long::fn' => sub { 'mocked' };
	is Um::Long::fn(), 'mocked', 'mock active';

	# Call unmock with two separate string arguments
	unmock('Um::Long', 'fn');
	is Um::Long::fn(), 'orig', 'longhand unmock restored original';
};

subtest 'unmock: croaks when method arg is empty string' => sub {
	dies_ok {
		unmock('Some::Pkg', '');
	} 'unmock croaks on empty method string';
};

subtest 'unmock: croaks when package arg is empty string' => sub {
	dies_ok {
		unmock('', 'method');
	} 'unmock croaks on empty package string';
};

# ===========================================================================
# 6. spy -- croak sub-condition and list-context return preservation
#    Line 589: croak unless $package && $method  (both sub-conditions)
#    Verify spy preserves original's list-context return value
# ===========================================================================

subtest 'spy: preserves list-context return from original' => sub {
	{
		package Spy::Ctx;
		sub multi { return ('p', 'q', 'r') }
	}

	my $spy = spy 'Spy::Ctx::multi';

	my @result = Spy::Ctx::multi();
	is_deeply \@result, ['p','q','r'], 'spy passes list return through';

	my @calls = $spy->();
	is scalar @calls, 1, 'spy captured the call';

	restore_all();
};

subtest 'spy: preserves scalar-context return from original' => sub {
	{
		package Spy::Scalar;
		sub count { 42 }
	}

	my $spy = spy 'Spy::Scalar::count';

	my $val = Spy::Scalar::count();
	is $val, 42, 'spy passes scalar return through';

	restore_all();
};

subtest 'spy: croaks when package resolves to empty' => sub {
	dies_ok {
		spy('', 'method');
	} 'spy croaks on empty package';
};

# ===========================================================================
# 7. mock_exception and mock_sequence -- individual croak sub-conditions
#    Line 855: unless defined $target && defined $message
#    Line 898: unless defined $target && @values
# ===========================================================================

subtest 'mock_exception: croaks when message is undef (target defined)' => sub {
	# $target is defined but $message is undef -- tests the && $message branch
	dies_ok {
		mock_exception 'Edge::Target::x', undef;
	} 'mock_exception croaks when message is undef';

	restore_all();
};

subtest 'mock_sequence: single value repeats on every call' => sub {
	{
		package MS::Single;
		sub fn { 'orig' }
	}

	# The @queue == 1 branch fires on every call once the queue drains to one
	mock_sequence 'MS::Single::fn' => ('only');
	is MS::Single::fn(), 'only', 'first call returns the single value';
	is MS::Single::fn(), 'only', 'second call repeats the single value';
	is MS::Single::fn(), 'only', 'third call still repeats';

	restore_all();
};

subtest 'mock_sequence: complex values (arrayrefs) returned correctly' => sub {
	{
		package MS::Complex;
		sub fn { [] }
	}

	my $r1 = [1, 2];
	my $r2 = [3, 4];
	mock_sequence 'MS::Complex::fn' => ($r1, $r2);

	is_deeply MS::Complex::fn(), [1,2], 'first complex value';
	is_deeply MS::Complex::fn(), [3,4], 'second complex value';
	is_deeply MS::Complex::fn(), [3,4], 'third call repeats last';

	restore_all();
};

# ===========================================================================
# 8. mock_return -- value-type edge cases
#    The croak checks $target not $value, so undef/0/'' values must work.
# ===========================================================================

subtest 'mock_return: undef value is returned correctly' => sub {
	{
		package MR::Types;
		sub fn { 'orig' }
	}

	mock_return 'MR::Types::fn' => undef;
	ok !defined MR::Types->can('fn')->(), 'mock_return with undef value';
	restore_all();
};

subtest 'mock_return: zero value is returned correctly' => sub {
	{
		package MR::Types;
		sub fn2 { 1 }
	}

	mock_return 'MR::Types::fn2' => 0;
	my $fn2 = MR::Types->can('fn2');
	is $fn2->(), 0, 'mock_return with 0 value';
	restore_all();
};

subtest 'mock_return: empty string value is returned correctly' => sub {
	{
		package MR::Types;
		sub fn3 { 'orig' }
	}

	mock_return 'MR::Types::fn3' => '';
	my $fn3 = MR::Types->can('fn3');
	is $fn3->(), '', 'mock_return with empty string';
	restore_all();
};

subtest 'mock_return: arrayref value is returned correctly' => sub {
	{
		package MR::Types;
		sub fn4 { undef }
	}

	my $ref = [1, 2, 3];
	mock_return 'MR::Types::fn4' => $ref;
	my $fn4 = MR::Types->can('fn4');
	is_deeply $fn4->(), $ref, 'mock_return with arrayref';
	restore_all();
};

# ===========================================================================
# 9. restore -- croak when target is undef
#    Line 998: croak 'restore requires a target' unless defined $target
# ===========================================================================

subtest 'restore: croaks on undef target' => sub {
	dies_ok { restore(undef) } 'restore croaks on undef target';
	like $@, qr/restore requires a target/, 'error message correct';
};

# ===========================================================================
# 10. deep_mock -- context branches, non-HASH plan, and exception propagation
#     Line 17:  croak unless ref $plan eq 'HASH'
#     Lines 25-30: $wantarray branches (list, scalar, void)
#     Line 41:  croak $err if $err
#     Line 42:  return $wantarray ? @ret : $ret
# ===========================================================================

{
	package DM::Ctx;
	sub fn { (10, 20, 30) }
}

subtest 'deep_mock: croaks when plan is not a hashref' => sub {
	dies_ok {
		deep_mock('not a hash', sub { });
	} 'non-hashref plan croaks';
	like $@, qr/HASHREF plan/, 'error message identifies HASHREF requirement';
};

subtest 'deep_mock: list context -- returns list from code block' => sub {
	my @result = deep_mock(
		{ mocks => [] },
		sub { return (1, 2, 3) }
	);
	is_deeply \@result, [1, 2, 3], 'deep_mock returns list in list context';
};

subtest 'deep_mock: scalar context -- returns scalar from code block' => sub {
	my $result = deep_mock(
		{ mocks => [] },
		sub { return 42 }
	);
	is $result, 42, 'deep_mock returns scalar in scalar context';
};

subtest 'deep_mock: exception in code block is re-thrown after cleanup' => sub {
	{
		package DM::Ex;
		sub fn { 'orig' }
	}

	dies_ok {
		deep_mock(
			{
				mocks => [
					{ target => 'DM::Ex::fn', type => 'mock', with => sub { 'mocked' } },
				],
			},
			sub { die "test error\n" }
		);
	} 'exception from code block is re-thrown';

	like $@, qr/test error/, 'original exception message preserved';

	# Mocks must be cleaned up even after the exception
	is DM::Ex::fn(), 'orig', 'mock restored after exception in code block';
};

subtest 'deep_mock: default mock type when type key is absent' => sub {
	{
		package DM::Default;
		sub fn { 'orig' }
	}

	# Omitting 'type' should default to 'mock', not croak
	deep_mock(
		{
			mocks => [
				{
					target => 'DM::Default::fn',
					# no 'type' key
					with   => sub { 'default_mocked' },
				},
			],
		},
		sub {
			is DM::Default::fn(), 'default_mocked',
				'absent type defaults to mock';
		}
	);

	is DM::Default::fn(), 'orig', 'original restored after default-type mock';
};

subtest 'deep_mock: spy without tag does not populate handles' => sub {
	{
		package DM::NoTag;
		sub fn { 1 }
	}

	# Spy with no tag: $handles->{$m->{tag}}{spy} branch is not taken.
	# Test simply confirms it does not croak.
	lives_ok {
		deep_mock(
			{
				mocks => [
					{ target => 'DM::NoTag::fn', type => 'spy' },  # no tag
				],
				expectations => [],
			},
			sub { DM::NoTag::fn() }
		);
	} 'spy without tag is accepted without error';
};

subtest 'deep_mock: inject without tag is accepted' => sub {
	{
		package DM::InjectNoTag;
		sub dep { 'real' }
	}

	lives_ok {
		deep_mock(
			{
				mocks => [
					{ target => 'DM::InjectNoTag::dep', type => 'inject', with => 'mocked' },
				],
			},
			sub {
				is DM::InjectNoTag::dep(), 'mocked', 'inject without tag works';
			}
		);
	} 'inject without tag is accepted without error';
};

subtest 'deep_mock: absent mocks key is treated as empty list' => sub {
	# Exercises the $plan->{mocks} || [] fallback in deep_mock:
	# a plan with no 'mocks' key must be accepted without croaking.
	{
		package DM::NoMocks;
		sub fn { 42 }
	}

	lives_ok {
		deep_mock(
			{ expectations => [] },   # 'mocks' key deliberately absent
			sub {
				is DM::NoMocks::fn(), 42,
					'original function unchanged when no mocks installed';
			}
		);
	} 'deep_mock with absent mocks key does not croak';
};

# ===========================================================================
# 11. TimeTravel -- uncovered branches
#     rewind_time() called while inactive  (line 52)
#     with_frozen_time() list context      (line 80)
#     _parse_timestamp('') empty string    (line 85)
#     _unit_to_seconds unknown unit        (line 118)
#     all unit strings: second/minute/hour/day and plurals
# ===========================================================================

subtest 'TimeTravel: rewind_time() dies when not active' => sub {
	Test::Mockingbird::TimeTravel::restore_all();
	dies_ok { rewind_time(10) } 'rewind_time croaks when inactive';
	like $@, qr/inactive/, 'error message mentions inactive';
};

subtest 'TimeTravel: with_frozen_time() returns list in list context' => sub {
	Test::Mockingbird::TimeTravel::restore_all();

	# Exercise the wantarray ? @ret : $ret[0] list branch
	my @result = with_frozen_time '2025-06-01T00:00:00Z' => sub {
		return (now(), now() + 1, now() + 2);
	};

	is scalar @result, 3, 'with_frozen_time returns list in list context';
	is $result[1], $result[0] + 1, 'list elements are correct';

	Test::Mockingbird::TimeTravel::restore_all();
};

subtest 'TimeTravel: _parse_timestamp croaks on empty string' => sub {
	# length($ts) is 0 -- the `&& length $ts` sub-condition fires
	my $parse = \&Test::Mockingbird::TimeTravel::_parse_timestamp;
	dies_ok { $parse->('') } '_parse_timestamp dies on empty string';
	like $@, qr/Invalid timestamp/, 'correct error category';
};

subtest 'TimeTravel: _unit_to_seconds croaks on unknown unit' => sub {
	freeze_time('2025-01-01T00:00:00Z');
	dies_ok { advance_time(1 => 'fortnights') } 'unknown unit croaks';
	like $@, qr/Unknown time unit/, 'error names the bad unit';
	Test::Mockingbird::TimeTravel::restore_all();
};

subtest 'TimeTravel: advance_time and rewind_time with all unit strings' => sub {
	# Test each unit independently by resetting to the base epoch before
	# each assertion; avoids cumulative arithmetic errors.
	my $check_advance = sub {
		my ($amount, $unit, $expected_delta, $label) = @_;
		Test::Mockingbird::TimeTravel::restore_all();
		freeze_time('2025-01-01T00:00:00Z');
		my $before = now();
		advance_time($amount => $unit);
		is now() - $before, $expected_delta, "advance_time $label";
	};

	my $check_rewind = sub {
		my ($amount, $unit, $expected_delta, $label) = @_;
		Test::Mockingbird::TimeTravel::restore_all();
		freeze_time('2025-01-01T00:00:00Z');
		my $before = now();
		rewind_time($amount => $unit);
		is $before - now(), $expected_delta, "rewind_time $label";
	};

	$check_advance->(1, 'second',  1,     '+1 second');
	$check_advance->(1, 'seconds', 1,     '+1 seconds (plural)');
	$check_advance->(2, 'minute',  120,   '+2 minutes');
	$check_advance->(1, 'minutes', 60,    '+1 minutes (plural)');
	$check_advance->(1, 'hour',    3600,  '+1 hour');
	$check_advance->(1, 'hours',   3600,  '+1 hours (plural)');
	$check_advance->(1, 'day',     86400, '+1 day');
	$check_advance->(1, 'days',    86400, '+1 days (plural)');

	$check_rewind->(1, 'second',  1,     '-1 second');
	$check_rewind->(1, 'minute',  60,    '-1 minute');
	$check_rewind->(1, 'hour',    3600,  '-1 hour');
	$check_rewind->(1, 'day',     86400, '-1 day');

	Test::Mockingbird::TimeTravel::restore_all();
};

subtest 'TimeTravel: with_frozen_time croaks on undef timestamp' => sub {
	# Tests the `unless defined $ts` branch (line 67 of TimeTravel)
	dies_ok { with_frozen_time undef, sub { } }
		'with_frozen_time croaks on undef timestamp';
};

# ===========================================================================
# 12. _parse_target -- deeply nested package names
#     The regex /^(.*)::([^:]+)$/ must split correctly for A::B::C::D::method
# ===========================================================================

subtest '_parse_target: handles four-level package name' => sub {
	{
		package A::B::C::D;
		sub deep_fn { 'orig' }
	}

	mock 'A::B::C::D::deep_fn' => sub { 'deep_mocked' };
	is A::B::C::D::deep_fn(), 'deep_mocked', 'four-level package mocked';
	restore_all();
	is A::B::C::D::deep_fn(), 'orig', 'four-level package restored';
};

# ===========================================================================
# 13. mock TYPE tracking -- verify each sugar function records correct type
#     Exercises $Test::Mockingbird::TYPE path in mock()
# ===========================================================================

subtest 'mock TYPE: each sugar function records its own type in metadata' => sub {
	{
		package TYPE::Check;
		sub a { 1 }
		sub b { 2 }
		sub c { 3 }
		sub d { 4 }
	}

	mock_return    'TYPE::Check::a' => 10;
	mock_exception 'TYPE::Check::b' => 'err';
	mock_sequence  'TYPE::Check::c' => (1, 2);
	mock_once      'TYPE::Check::d' => sub { 99 };

	my $diag = diagnose_mocks();

	is $diag->{'TYPE::Check::a'}{layers}[0]{type}, 'mock_return',
		'mock_return records correct type';
	is $diag->{'TYPE::Check::b'}{layers}[0]{type}, 'mock_exception',
		'mock_exception records correct type';
	is $diag->{'TYPE::Check::c'}{layers}[0]{type}, 'mock_sequence',
		'mock_sequence records correct type';
	is $diag->{'TYPE::Check::d'}{layers}[0]{type}, 'mock_once',
		'mock_once records correct type';

	restore_all();
};

# ===========================================================================
# 14. restore_all package-specific -- multiple mocked methods in same package,
#     and a package whose name is a prefix of another (no spurious matches)
# ===========================================================================

subtest 'restore_all: package-specific restores only matching methods' => sub {
	{
		package RA::Target;
		sub x { 'x' }
		sub y { 'y' }
	}
	{
		package RA::TargetExtra;  # starts with 'RA::Target' but is different
		sub z { 'z' }
	}

	mock 'RA::Target::x'      => sub { 'X' };
	mock 'RA::Target::y'      => sub { 'Y' };
	mock 'RA::TargetExtra::z' => sub { 'Z' };

	restore_all 'RA::Target';

	is RA::Target::x(),      'x', 'RA::Target::x restored';
	is RA::Target::y(),      'y', 'RA::Target::y restored';
	is RA::TargetExtra::z(), 'Z', 'RA::TargetExtra::z still mocked (different pkg)';

	restore_all();
	is RA::TargetExtra::z(), 'z', 'RA::TargetExtra::z restored after full restore_all';
};

# ===========================================================================
# 15. mock + spy interaction -- spy layered on top of mock
#     Verifies call recording works when both layers are active
# ===========================================================================

subtest 'mock then spy: spy records calls going through the mock' => sub {
	{
		package Interact::A;
		sub fn { 'orig' }
	}

	# Install mock first (lower layer), then spy on top
	mock 'Interact::A::fn' => sub { 'mocked' };
	my $spy = spy 'Interact::A::fn';

	Interact::A::fn('arg1');
	Interact::A::fn('arg2');

	my @calls = $spy->();
	is scalar @calls, 2, 'spy captured both calls through the mock layer';

	restore_all();
	is Interact::A::fn(), 'orig', 'original restored after both layers removed';
};

subtest 'spy then mock: upper mock layer shadows spy return value' => sub {
	{
		package Interact::B;
		sub fn { 'orig' }
	}

	# Install spy first (lower layer), then mock on top
	my $spy = spy 'Interact::B::fn';
	mock 'Interact::B::fn' => sub { 'top' };

	my $result = Interact::B::fn('x');

	# The top mock's return value wins; the spy records via $orig (the
	# spy wrapper), which is bypassed by the upper mock in normal flow.
	is $result, 'top', 'top mock return value returned';

	restore_all();
};


# ===========================================================================
# 17. Targeted condition-coverage patches
#     These subtests specifically target the * 33 / * 50 / * 66 conditions
#     remaining after the subtests above, to push lib file coverage to 95%+.
# ===========================================================================

# -- mock() croak sub-conditions (line 258: $package && $method && $replacement) --

subtest 'mock(): croaks when package is empty string' => sub {
	# Tests the first sub-condition ($package) being falsy
	dies_ok { mock('', 'method', sub { }) }
		'mock() croaks on empty package string';
};

subtest 'mock(): croaks when method is empty string' => sub {
	# Tests $package truthy but $method falsy
	dies_ok { mock('Some::Pkg', '', sub { }) }
		'mock() croaks on empty method string';
};

subtest 'mock(): shorthand with non-:: arg1 falls to longhand parse' => sub {
	# 'NoColons' has no :: so the shorthand regex does not match;
	# mock() falls through to the longhand branch and treats
	# arg1 as $package and arg2 as $method.  With arg3 defined this
	# exercises the regex-match-false sub-condition on line 250.
	{
		package NoColons;
		sub fn { 'orig' }
	}
	mock('NoColons', 'fn', sub { 'patched' });
	is NoColons::fn(), 'patched', 'mock() works with un-namespaced package';
	restore_all();
};

# -- mock_scoped() 2-arg with non-CODE second arg (line 453 condition) --

subtest 'mock_scoped(): 2 args but second is not CODE reaches croak' => sub {
	# @args == 2 but ref($args[1]) ne 'CODE' -- the first arm fails,
	# all subsequent arms also fail, reaching the croak.
	dies_ok {
		mock_scoped('Pkg::method', 'not_a_coderef');
	} 'mock_scoped croaks when 2 args but second is not CODE';
};

# -- unmock() shorthand where arg1 has no :: (line 315 condition) --

subtest 'unmock(): shorthand with non-:: string uses longhand parse' => sub {
	# 'NoColons::fn' already mocked above.  Unmock via the 2-arg form
	# where arg1 is 'NoColons' (no ::) exercises the regex-false branch.
	{
		package NC2;
		sub fn { 'orig' }
	}
	mock('NC2', 'fn', sub { 'patched' });
	unmock('NC2', 'fn');   # longhand form, arg1 'NC2' has no ::
	is NC2::fn(), 'orig', 'longhand unmock worked on plain-name package';
};

# -- deep_mock restore_on_scope_exit => 1 (line 36 explicit-true branch) --

subtest 'deep_mock: explicit restore_on_scope_exit => 1 restores mocks' => sub {
	{
		package DM::ExplicitRestore;
		sub fn { 'orig' }
	}

	deep_mock(
		{
			globals => { restore_on_scope_exit => 1 },
			mocks   => [
				{ target => 'DM::ExplicitRestore::fn', type => 'mock',
				  with   => sub { 'mocked' } },
			],
		},
		sub {
			is DM::ExplicitRestore::fn(), 'mocked',
				'mock active inside deep_mock with explicit restore_on_scope_exit 1';
		}
	);

	is DM::ExplicitRestore::fn(), 'orig',
		'mock restored with explicit restore_on_scope_exit => 1';
};

# -- deep_mock: mock with `with` defined but not CODE (line 54 second sub-cond) --

subtest 'deep_mock: mock with non-CODE `with` value croaks' => sub {
	dies_ok {
		deep_mock(
			{
				mocks => [
					{ target => 'Any::Pkg::fn', type => 'mock',
					  with   => 'a string, not a coderef' },
				],
			},
			sub { }
		);
	} 'mock with non-CODE with value croaks';
};

# -- deep_mock: inject with tag (line 65 inject-tag branch) --

subtest 'deep_mock: inject with tag stores handle correctly' => sub {
	{
		package DM::InjectTag;
		sub dep { 'real' }
	}

	# The inject-with-tag branch ($handles->{ $m->{tag} }{inject} = 1)
	# is exercised when inject has a tag.  We cannot write an expectation
	# against an inject (only spies have recorded calls), so we simply
	# verify the mock works and is restored.
	deep_mock(
		{
			mocks => [
				{ target => 'DM::InjectTag::dep', type => 'inject',
				  with   => 'MOCK', tag => 'dep_handle' },
			],
		},
		sub {
			is DM::InjectTag::dep(), 'MOCK',
				'inject with tag is active inside block';
		}
	);

	is DM::InjectTag::dep(), 'real', 'original restored after inject-with-tag';
};

# -- _run_expectations args_like with string regex (line 91: ref $re ? $re : qr/$re/) --

subtest '_run_expectations: args_like accepts plain string regex' => sub {
	{
		package DM::StringRe;
		sub fn { $_[0] }
	}

	my %handles;
	my $spy = Test::Mockingbird::spy('DM::StringRe', 'fn');
	$handles{s}{spy} = $spy;

	DM::StringRe::fn('hello_world');

	# Pass a plain string instead of a compiled regex -- exercises
	# the `ref $re ? $re : qr/$re/` false-branch (ref is undef for string)
	Test::Mockingbird::DeepMock::_run_expectations(
		[
			{
				tag       => 's',
				calls     => 1,
				args_like => [ [ 'hello' ] ],   # plain string, not qr//
			}
		],
		\%handles,
	);

	Test::Mockingbird::restore_all();
};

# -- _apply_time_plan travel/advance/rewind branches (lines 136-142) --

subtest 'deep_mock: time plan with travel_to is applied' => sub {
	{
		package DM::TimeTravel;
		sub ts { 0 }
	}

	my $seen;
	deep_mock(
		{
			time  => {
				freeze => '2025-01-01T00:00:00Z',
				travel => '2025-06-15T12:00:00Z',  # exercises travel branch
			},
			mocks => [
				{ target => 'DM::TimeTravel::ts', type => 'mock',
				  with   => sub { now() } },
			],
		},
		sub { $seen = DM::TimeTravel::ts() }
	);

	my $expected = Test::Mockingbird::TimeTravel::_parse_datetime(
		'2025-06-15T12:00:00Z'
	);
	is $seen, $expected, 'travel_to applied in deep_mock time plan';
};

subtest 'deep_mock: time plan with rewind_time is applied' => sub {
	{
		package DM::TimeRewind;
		sub ts { 0 }
	}

	my $seen;
	deep_mock(
		{
			time  => {
				freeze => '2025-01-01T12:00:00Z',
				rewind => [ 1 => 'hour' ],         # exercises rewind branch
			},
			mocks => [
				{ target => 'DM::TimeRewind::ts', type => 'mock',
				  with   => sub { now() } },
			],
		},
		sub { $seen = DM::TimeRewind::ts() }
	);

	my $expected = Test::Mockingbird::TimeTravel::_parse_datetime(
		'2025-01-01T11:00:00Z'
	);
	is $seen, $expected, 'rewind_time applied in deep_mock time plan';
};

# -- spy() longhand 2-arg form (line 589 _parse_target longhand path) --

subtest 'spy(): longhand 2-arg form works correctly' => sub {
	{
		package Spy::Long;
		sub fn { 42 }
	}

	# Explicit 2-arg form: spy($package, $method)
	my $spy = spy('Spy::Long', 'fn');
	Spy::Long::fn();
	my @calls = $spy->();

	is scalar @calls, 1,              'spy() longhand captured the call';
	is $calls[0][0], 'Spy::Long::fn', 'method name recorded correctly';

	restore_all();
};

done_testing();
