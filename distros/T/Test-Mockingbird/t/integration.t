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
	restore_all
	with_frozen_time
);

# ----------------------------------------------------------------------
# INTEGRATION LEVEL TESTS
# ----------------------------------------------------------------------

{
	package DMTest;
	our $VALUE = 10;
	sub greet  { "orig" }
	sub double { ($_[1] // 0) * 2 }
	sub getval { $VALUE }
	sub setval { $VALUE = $_[1] }
}

subtest 'basic mock replaces method' => sub {
	deep_mock(
		{
			mocks => [
				{ target => 'DMTest::greet', type => 'mock', with => sub { "mocked" } },
			],
		},
		sub { is DMTest::greet(), 'mocked', 'greet() was mocked' }
	);
	is DMTest::greet(), 'orig', 'mock restored after deep_mock';
};

subtest 'spy captures calls and arguments' => sub {
	deep_mock(
		{
			mocks => [
				{ target => 'DMTest::double', type => 'spy', tag => 'dbl' },
			],
			expectations => [ { tag => 'dbl', calls => 2 } ],
		},
		sub {
			DMTest::double(2);
			DMTest::double(5);
		}
	);
};

subtest 'inject replaces value or behavior' => sub {
	deep_mock(
		{
			mocks => [
				{ target => 'DMTest::getval', type => 'inject', with => 999 },
			],
		},
		sub { is DMTest::getval(), 999, 'inject replaced getval' }
	);
	is DMTest::getval(), 10, 'inject restored after deep_mock';
};

subtest 'multiple mocks + spy + expectations' => sub {
	deep_mock(
		{
			mocks => [
				{ target => 'DMTest::greet',  type => 'mock', with => sub { "hi" } },
				{ target => 'DMTest::double', type => 'spy',  tag  => 'dbl' },
			],
			expectations => [ { tag => 'dbl', calls => 3 } ],
		},
		sub {
			is DMTest::greet(), 'hi', 'greet mocked';
			DMTest::double(1);
			DMTest::double(2);
			DMTest::double(3);
		}
	);
};

subtest 'argument pattern expectations' => sub {
	deep_mock(
		{
			mocks => [
				{ target => 'DMTest::double', type => 'spy', tag => 'dbl' },
			],
			expectations => [
				{
					tag       => 'dbl',
					calls     => 2,
					args_like => [ [ qr/^10$/ ], [ qr/^20$/ ] ],
				},
			],
		},
		sub {
			DMTest::double(10);
			DMTest::double(20);
		}
	);
};

subtest 'restore_on_scope_exit => 0 keeps mocks active' => sub {
	deep_mock(
		{
			globals => { restore_on_scope_exit => 0 },
			mocks   => [
				{ target => 'DMTest::greet', type => 'mock', with => sub { "persist" } },
			],
		},
		sub { is DMTest::greet(), 'persist', 'mock active inside deep_mock' }
	);
	is DMTest::greet(), 'persist', 'mock persists after deep_mock';
	Test::Mockingbird::restore_all();
	is DMTest::greet(), 'orig', 'manual restore_all works';
};

subtest 'unknown mock type throws error' => sub {
	dies_ok {
		deep_mock(
			{ mocks => [ { target => 'DMTest::greet', type => 'wut' } ] },
			sub { }
		);
	} 'unknown mock type dies';
};

subtest 'missing spy tag in expectation dies' => sub {
	dies_ok {
		deep_mock(
			{
				mocks => [
					{ target => 'DMTest::double', type => 'spy', tag => 'dbl' },
				],
				expectations => [ { calls => 1 } ],
			},
			sub { DMTest::double(1) }
		);
	} 'missing tag in expectation dies';
};

subtest 'args_eq works' => sub {
	{
		package DM_EQ;
		sub foo { $_[1] }
	}

	deep_mock(
		{
			mocks => [
				{ target => 'DM_EQ::foo', type => 'spy', tag => 's' },
			],
			expectations => [
				{ tag => 's', args_eq => [ ['alpha'], ['beta'] ] },
			],
		},
		sub {
			DM_EQ::foo('alpha');
			DM_EQ::foo('beta');
		}
	);
};

subtest 'args_deeply works' => sub {
	{
		package DM_DEEP;
		sub foo { $_[1] }
	}

	deep_mock(
		{
			mocks => [
				{ target => 'DM_DEEP::foo', type => 'spy', tag => 's' },
			],
			expectations => [
				{
					tag        => 's',
					args_deeply => [
						[ { a => 1, b => [2,3] } ],
						[ { x => 9 } ],
					],
				},
			],
		},
		sub {
			DM_DEEP::foo({ a => 1, b => [2,3] });
			DM_DEEP::foo({ x => 9 });
		}
	);
};

subtest 'never works' => sub {
	{
		package DM_NEVER;
		sub foo { $_[1] }
	}

	deep_mock(
		{
			mocks => [
				{ target => 'DM_NEVER::foo', type => 'spy', tag => 's' },
			],
			expectations => [ { tag => 's', never => 1 } ],
		},
		sub { }
	);
};

subtest 'combined mock_return + mock_exception + mock_sequence' => sub {
	{
		package Edge::Service;
		sub status { return 'ok' }
	}

	mock_return    'Edge::Service::status' => 'warmup';
	mock_sequence  'Edge::Service::status' => ('retry1', 'retry2', 'steady');
	mock_exception 'Edge::Service::status' => 'fatal';

	dies_ok { Edge::Service::status() } 'topmost mock_exception wins';
	like $@, qr/fatal/, 'fatal error seen';

	Test::Mockingbird::restore_all();
	is Edge::Service::status(), 'ok', 'original restored';
};

subtest 'mock_once with retry logic' => sub {
	{
		package Edge::Service;
		sub ping { return 'ok' }
	}

	mock_once 'Edge::Service::ping' => sub { 'fail' };
	is Edge::Service::ping(), 'fail', 'first call fails';
	is Edge::Service::ping(), 'ok',   'second call succeeds';
	restore_all();
};

subtest 'restore interacts correctly with mock_once and mock_sequence' => sub {
	{
		package Edge::Restore;
		sub c { return 'orig' }
	}

	mock_sequence 'Edge::Restore::c' => (10, 20);
	mock_once     'Edge::Restore::c' => sub { 99 };

	is Edge::Restore::c(), 99, 'mock_once fires first';
	restore 'Edge::Restore::c';
	is Edge::Restore::c(), 'orig', 'restore removes all layers';
	restore_all();
};

subtest 'diagnose_mocks integrates with spy and inject' => sub {
	{
		package DM::I1;
		sub c   { 1 }
		sub dep { 2 }
	}

	spy    'DM::I1::c';
	inject 'DM::I1::dep' => sub { 99 };

	my $diag = diagnose_mocks();
	ok exists $diag->{'DM::I1::c'},   'spy recorded';
	ok exists $diag->{'DM::I1::dep'}, 'inject recorded';
	restore_all();
};

my $parse = sub { Test::Mockingbird::TimeTravel::_parse_datetime($_[0]) };

subtest 'freeze_time + now + restore_all (end-to-end)' => sub {
	restore_all();
	my $epoch = freeze_time('2025-01-01T00:00:00Z');
	is now(), $epoch, 'now() returns frozen epoch';
	restore_all();
	isnt now(), $epoch, 'restore_all() returns real time';
};

subtest 'advance_time + rewind_time across multiple units' => sub {
	restore_all();
	freeze_time('2025-01-01T00:00:00Z');
	my $t0 = now();
	advance_time(30);
	is now(), $t0 + 30, 'advance_time +30 seconds';
	advance_time(2 => 'minutes');
	is now(), $t0 + 30 + 120, 'advance_time +2 minutes';
	advance_time(1 => 'hour');
	is now(), $t0 + 30 + 120 + 3600, 'advance_time +1 hour';
	rewind_time(90);
	is now(), $t0 + 30 + 120 + 3600 - 90, 'rewind_time -90 seconds';
	rewind_time(1 => 'minute');
	is now(), $t0 + 30 + 120 + 3600 - 90 - 60, 'rewind_time -1 minute';
	restore_all();
};

subtest 'travel_to overrides frozen time' => sub {
	restore_all();
	freeze_time('2025-01-01T00:00:00Z');
	travel_to('2025-01-03T12:34:56Z');
	is now(), $parse->('2025-01-03T12:34:56Z'), 'travel_to sets new frozen epoch';
	restore_all();
};

subtest 'with_frozen_time temporarily overrides time' => sub {
	restore_all();
	my $outer = freeze_time('2025-01-01T00:00:00Z');
	my $inner;
	with_frozen_time '2025-01-02T00:00:00Z' => sub { $inner = now() };
	is $inner, $parse->('2025-01-02T00:00:00Z'), 'inner block sees overridden time';
	is now(), $outer, 'outer time restored after block';
	restore_all();
};

subtest 'nested with_frozen_time blocks restore correctly' => sub {
	restore_all();
	freeze_time('2025-01-01T00:00:00Z');
	my ($inner1, $inner2);
	with_frozen_time '2025-01-02T00:00:00Z' => sub {
		$inner1 = now();
		with_frozen_time '2025-01-03T00:00:00Z' => sub { $inner2 = now() };
		is now(), $parse->('2025-01-02T00:00:00Z'),
			'after inner block, outer block time restored';
	};
	is $inner1, $parse->('2025-01-02T00:00:00Z'), 'first-level block saw correct time';
	is $inner2, $parse->('2025-01-03T00:00:00Z'), 'nested block saw correct time';
	is now(), $parse->('2025-01-01T00:00:00Z'), 'after all blocks, original time restored';
	restore_all();
};

subtest 'with_frozen_time propagates exceptions and restores state' => sub {
	restore_all();
	freeze_time('2025-01-01T00:00:00Z');
	eval {
		with_frozen_time '2025-01-02T00:00:00Z' => sub { die "boom" };
	};
	like $@, qr/boom/, 'exception propagated from block';
	is now(), $parse->('2025-01-01T00:00:00Z'), 'state restored after exception';
	restore_all();
};

subtest 'timestamp formats accepted end-to-end' => sub {
	restore_all();
	my @formats = (
		'2025-01-01T00:00:00Z',
		'2025-01-01 00:00:00',
		'2025-01-01',
		$parse->('2025-01-01T00:00:00Z'),
	);
	for my $ts (@formats) {
		freeze_time($ts);
		is now(), $parse->('2025-01-01T00:00:00Z'), "format '$ts' parsed correctly";
		restore_all();
	}
};

subtest 'deep_mock integrates time plan + mocks end-to-end' => sub {
	restore_all();
	Test::Mockingbird::restore_all();

	{
		package DM_TIME;
		sub stamp { 0 }
	}

	my $seen;
	deep_mock(
		{
			time  => {
				freeze  => '2025-01-01T00:00:00Z',
				advance => [ 2 => 'minutes' ],
			},
			mocks => [
				{
					target => 'DM_TIME::stamp',
					type   => 'mock',
					with   => sub { Test::Mockingbird::TimeTravel::now() },
				},
			],
		},
		sub { $seen = DM_TIME::stamp() }
	);

	is $seen, $parse->('2025-01-01T00:02:00Z'),
		'deep_mock time plan applied to mocked method';
	isnt now(), $parse->('2025-01-01T00:02:00Z'), 'time restored after deep_mock';
	is DM_TIME::stamp(), 0, 'original DM_TIME::stamp restored';

	restore_all();
	Test::Mockingbird::restore_all();
};

# ----------------------------------------------------------------------
# PROTOTYPE PRESERVATION -- INTEGRATION TESTS
#
# End-to-end tests that verify the set_prototype fix eliminates
# prototype-mismatch warnings across a full mock/use/restore cycle,
# including via deep_mock.
# ----------------------------------------------------------------------

subtest 'prototyped function mocked and restored cleanly without warnings' => sub {
	# Mimics I18N::LangTags::Detect::detect, which has a () prototype and
	# previously caused "Prototype mismatch: sub ... ()" warnings when mocked.
	{
		package Proto::Integ::Detect;
		sub detect () { 'real' }
	}

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, $_[0] };

	# Use ->can() throughout to avoid compile-time constant folding of ()
	my $fn = sub { Proto::Integ::Detect->can('detect')->() };

	is $fn->(), 'real', 'original value before mock';

	mock 'Proto::Integ::Detect::detect' => sub { 'mocked' };
	is $fn->(), 'mocked', 'mock active (via ->can())';

	# restore_all is imported from TimeTravel in this file; use the
	# fully-qualified name to restore the Mockingbird mock layer.
	Test::Mockingbird::restore_all();
	is $fn->(), 'real', 'original restored (via ->can())';

	ok !@warnings, 'no prototype-mismatch warnings throughout cycle';
};

subtest 'deep_mock on () prototype function emits no warnings' => sub {
	{
		package Proto::Integ::DeepMock;
		sub stamp () { 0 }
	}

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, $_[0] };

	# Wrap all calls in a ->can() closure to bypass compile-time constant folding
	my $stamp = sub { Proto::Integ::DeepMock->can('stamp')->() };

	deep_mock(
		{
			mocks => [
				{
					target => 'Proto::Integ::DeepMock::stamp',
					type   => 'mock',
					with   => sub { 42 },
				},
			],
		},
		sub {
			is $stamp->(), 42,
				'prototyped function mocked correctly via deep_mock';
		}
	);

	is $stamp->(), 0, 'original restored after deep_mock';
	ok !@warnings, 'no warnings during deep_mock on prototyped function';
};

subtest 'mock_scoped on () prototype function emits no warnings' => sub {
	{
		package Proto::Integ::Scoped;
		sub fn () { 'orig' }
	}

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, $_[0] };

	# Use ->can() to call through the symbol table at runtime
	my $fn_scoped = sub { Proto::Integ::Scoped->can('fn')->() };

	{
		my $g = mock_scoped 'Proto::Integ::Scoped::fn' => sub { 'scoped' };
		is $fn_scoped->(), 'scoped', 'scoped mock active (via ->can())';
	}

	is $fn_scoped->(), 'orig', 'original restored on guard destruction (via ->can())';
	ok !@warnings, 'no warnings during mock_scoped on prototyped function';
};

done_testing();
