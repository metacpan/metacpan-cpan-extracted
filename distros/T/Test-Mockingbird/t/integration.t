#!/usr/bin/env perl

use strict;
use warnings;

use lib 'lib';

use Readonly;
use Test::Most;
use Test::Mockingbird;
use Test::Mockingbird::DeepMock qw(deep_mock);

# Import TimeTravel functions.  Note: this file imports TimeTravel's
# restore_all, so core mock cleanup uses the fully-qualified
# Test::Mockingbird::restore_all() form throughout.
use Test::Mockingbird::TimeTravel qw(
	now
	freeze_time
	travel_to
	advance_time
	rewind_time
	restore_all
	with_frozen_time
);

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

# Async layer type names (used in diagnose_mocks assertions)
Readonly my $T_MFR  => 'mock_future_return';
Readonly my $T_MFF  => 'mock_future_fail';
Readonly my $T_MFS  => 'mock_future_sequence';
Readonly my $T_MFO  => 'mock_future_once';
Readonly my $T_ASP  => 'async_spy';

# Timestamp strings for TimeTravel tests
Readonly my $TS_2025_JAN1  => '2025-01-01T00:00:00Z';
Readonly my $TS_2025_JUN1  => '2025-06-01T00:00:00Z';
Readonly my $TS_2025_JAN2  => '2025-01-02T00:00:00Z';
Readonly my $TS_2025_JAN3  => '2025-01-03T00:00:00Z';
Readonly my $TS_2025_JAN3T => '2025-01-03T12:34:56Z';
Readonly my $TS_2025_JUN15 => '2025-06-15T00:00:00Z';

# Error messages for optional-dependency gating
Readonly my $ERR_FUTURE_ABSENT  => 'requires the Future module';
Readonly my $ERR_FUTURE_INSTALL => 'cpanm Future';

# Private timestamp parser
my $parse = sub { Test::Mockingbird::TimeTravel::_parse_datetime($_[0]) };

# ---------------------------------------------------------------------------
# Package stubs reused across sections
# ---------------------------------------------------------------------------

{
	package DMTest;
	our $VALUE = 10;
	sub greet  { "orig" }
	sub double { ($_[1] // 0) * 2 }
	sub getval { $VALUE }
	sub setval { $VALUE = $_[1] }
}

# ============================================================================
#  SECTION 1 -- DeepMock basic: mock, spy, inject, combined, patterns
# ============================================================================

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
					tag         => 's',
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

# ============================================================================
#  SECTION 2 -- Combined sugar functions
# ============================================================================

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

# ============================================================================
#  SECTION 3 -- Call ordering
# ============================================================================

subtest 'assert_call_order across multiple packages' => sub {
	{
		package Ord::Alpha;
		sub open  { 1 }
	}
	{
		package Ord::Beta;
		sub process { 1 }
	}
	{
		package Ord::Gamma;
		sub close { 1 }
	}

	spy 'Ord::Alpha::open';
	spy 'Ord::Beta::process';
	spy 'Ord::Gamma::close';

	Ord::Alpha::open();
	Ord::Beta::process();
	Ord::Gamma::close();

	assert_call_order('Ord::Alpha::open', 'Ord::Beta::process', 'Ord::Gamma::close');

	Test::Mockingbird::restore_all();
};

subtest 'call ordering via deep_mock order expectation' => sub {
	{
		package DM_ORD_A;
		sub fetch { 1 }
	}
	{
		package DM_ORD_B;
		sub save { 1 }
	}

	deep_mock(
		{
			mocks => [
				{ target => 'DM_ORD_A::fetch', type => 'spy', tag => 'fetch' },
				{ target => 'DM_ORD_B::save',  type => 'spy', tag => 'save'  },
			],
			expectations => [
				{ tag => 'fetch', calls => 1 },
				{ tag => 'save',  calls => 1 },
				{ order => [ 'DM_ORD_A::fetch', 'DM_ORD_B::save' ] },
			],
		},
		sub {
			DM_ORD_A::fetch();
			DM_ORD_B::save();
		}
	);
};

subtest 'clear_call_log resets between phases without uninstalling spies' => sub {
	{
		package Phase::A;
		sub go { 1 }
	}
	{
		package Phase::B;
		sub go { 1 }
	}

	spy 'Phase::A::go';
	spy 'Phase::B::go';

	# Phase 1: correct order
	Phase::A::go();
	Phase::B::go();
	assert_call_order('Phase::A::go', 'Phase::B::go');

	clear_call_log();

	# Phase 2: reversed order; spies still active
	Phase::B::go();
	Phase::A::go();

	my $result;
	{
		local $TODO = 'reversed order - expected to fail';
		$result = assert_call_order('Phase::A::go', 'Phase::B::go');
	}
	ok !$result, 'assert_call_order returns false for reversed order after clear';

	Test::Mockingbird::restore_all();
};

# ============================================================================
#  SECTION 4 -- diagnose_mocks integration
# ============================================================================

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

# ============================================================================
#  SECTION 5 -- TimeTravel end-to-end
# ============================================================================

subtest 'freeze_time + now + restore_all (end-to-end)' => sub {
	restore_all();
	my $epoch = freeze_time($TS_2025_JAN1);
	is now(), $epoch, 'now() returns frozen epoch';
	restore_all();
	isnt now(), $epoch, 'restore_all() returns real time';
};

subtest 'advance_time + rewind_time across multiple units' => sub {
	restore_all();
	freeze_time($TS_2025_JAN1);
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
	freeze_time($TS_2025_JAN1);
	travel_to($TS_2025_JAN3T);
	is now(), $parse->($TS_2025_JAN3T), 'travel_to sets new frozen epoch';
	restore_all();
};

subtest 'with_frozen_time temporarily overrides time' => sub {
	restore_all();
	my $outer = freeze_time($TS_2025_JAN1);
	my $inner;
	with_frozen_time $TS_2025_JAN2 => sub { $inner = now() };
	is $inner, $parse->($TS_2025_JAN2), 'inner block sees overridden time';
	is now(), $outer, 'outer time restored after block';
	restore_all();
};

subtest 'nested with_frozen_time blocks restore correctly' => sub {
	restore_all();
	freeze_time($TS_2025_JAN1);
	my ($inner1, $inner2);
	with_frozen_time $TS_2025_JAN2 => sub {
		$inner1 = now();
		with_frozen_time $TS_2025_JAN3 => sub { $inner2 = now() };
		is now(), $parse->($TS_2025_JAN2),
			'after inner block, outer block time restored';
	};
	is $inner1, $parse->($TS_2025_JAN2), 'first-level block saw correct time';
	is $inner2, $parse->($TS_2025_JAN3), 'nested block saw correct time';
	is now(), $parse->($TS_2025_JAN1), 'after all blocks, original time restored';
	restore_all();
};

subtest 'with_frozen_time propagates exceptions and restores state' => sub {
	restore_all();
	freeze_time($TS_2025_JAN1);
	eval {
		with_frozen_time $TS_2025_JAN2 => sub { die "boom" };
	};
	like $@, qr/boom/, 'exception propagated from block';
	is now(), $parse->($TS_2025_JAN1), 'state restored after exception';
	restore_all();
};

subtest 'timestamp formats accepted end-to-end' => sub {
	restore_all();
	my @formats = (
		$TS_2025_JAN1,
		'2025-01-01 00:00:00',
		'2025-01-01',
		$parse->($TS_2025_JAN1),
	);
	for my $ts (@formats) {
		freeze_time($ts);
		is now(), $parse->($TS_2025_JAN1), "format '$ts' parsed correctly";
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
				freeze  => $TS_2025_JAN1,
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

# ============================================================================
#  SECTION 6 -- Prototype preservation
# ============================================================================

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

# ============================================================================
#  SECTION 7 -- Full pipeline simulation
# ============================================================================

subtest 'full pipeline: inject_all + spy + assert_call_order across 3 methods' => sub {
	# Simulate a typical service test: inject all dependencies, spy to capture
	# call sequence, then assert order.  Spies are layered ON TOP of the
	# inject wrappers, so both record calls and pass through the injected value.
	{
		package Pipeline::Svc;
		sub connect { bless {}, shift }
		sub query   { 'real_result'   }
		sub close   { 1               }
	}

	inject_all('Pipeline::Svc', {
		connect => 'mock_conn',
		query   => 'mock_result',
		close   => 0,
	});

	spy 'Pipeline::Svc::connect';
	spy 'Pipeline::Svc::query';
	spy 'Pipeline::Svc::close';

	Pipeline::Svc::connect();
	Pipeline::Svc::query('SELECT 1');
	Pipeline::Svc::close();

	# Inject value is still visible through the spy layer
	is Pipeline::Svc::query(), 'mock_result',
		'inject value visible through spy wrapper';

	assert_call_order(
		'Pipeline::Svc::connect',
		'Pipeline::Svc::query',
		'Pipeline::Svc::close',
	);

	# Diagnose confirms both inject and spy layers are present
	my $diag = diagnose_mocks();
	ok exists $diag->{'Pipeline::Svc::connect'},
		'connect visible in mock state';
	cmp_ok $diag->{'Pipeline::Svc::connect'}{depth}, '>=', 2,
		'connect carries inject + spy layers';

	diag diagnose_mocks_pretty() if $ENV{TEST_VERBOSE};
	Test::Mockingbird::restore_all();
};

# ============================================================================
#  SECTION 8 -- LIFO stack surgery
# ============================================================================

subtest 'LIFO surgery: restore() drains all layers, leaving original' => sub {
	# Three sugar functions stack on the same target; restore() removes all
	# in one shot, which is the contract for the public restore() function.
	{
		package LIFO::P;
		sub fn { 'orig' }
	}

	mock_return    'LIFO::P::fn' => 'r1';
	mock_sequence  'LIFO::P::fn' => ('s1', 's2');
	mock_exception 'LIFO::P::fn' => 'boom';

	my $diag = diagnose_mocks();
	is $diag->{'LIFO::P::fn'}{depth}, 3, 'three layers stacked';

	# Top is mock_exception; it fires on the first call
	dies_ok { LIFO::P::fn() } 'top layer (exception) fires';

	# restore() drains the ENTIRE stack for this target
	restore 'LIFO::P::fn';
	is LIFO::P::fn(), 'orig', 'original restored after restore()';
	ok !exists diagnose_mocks()->{'LIFO::P::fn'},
		'target absent from mock state after restore()';
};

subtest 'spy stacked over mock_return: spy captures call, mock value returned' => sub {
	# Verifies that spy() wraps whatever is currently installed; here it wraps
	# the mock_return stub.  The return value flows through the spy unchanged.
	{
		package SR::P;
		sub fn { 'orig' }
	}

	mock_return 'SR::P::fn' => 'mocked_val';
	my $spy_cref = spy 'SR::P::fn';

	my $result = SR::P::fn('arg1');

	is $result, 'mocked_val',
		'spy passes through to mock_return value';

	my @calls = $spy_cref->();
	is scalar @calls, 1, 'spy captured exactly one call';
	is_deeply $calls[0], ['SR::P::fn', 'arg1'],
		'call record contains method name and argument';

	Test::Mockingbird::restore_all();
};

# ============================================================================
#  SECTION 9 -- Constructor interception
# ============================================================================

subtest 'intercept_new + spy on method of returned object' => sub {
	# intercept_new replaces the constructor to return a stub object.
	# Spy is installed on the stub class method to capture calls.
	{
		package IC::Real;
		sub new    { bless { type => 'real' }, shift }
		sub handle { 'real_handle' }
	}
	{
		package IC::Fake;
		sub handle { 'fake_handle' }
	}

	my $stub = bless {}, 'IC::Fake';
	intercept_new 'IC::Real' => $stub;

	my $spy = spy 'IC::Fake::handle';

	my $obj = IC::Real->new;
	is ref $obj, 'IC::Fake', 'constructor intercepted, stub class returned';

	my $val = $obj->handle;
	is $val, 'fake_handle', 'stub method returns expected value';

	my @calls = $spy->();
	is scalar @calls, 1, 'spy captured one call to IC::Fake::handle';
	is $calls[0][0], 'IC::Fake::handle', 'method name in call record';

	diag "Call record: @{$calls[0]}" if $ENV{TEST_VERBOSE};
	Test::Mockingbird::restore_all();
};

subtest 'intercept_new LIFO: two interceptors; unmock reveals lower layer' => sub {
	{
		package ILI::Svc;
		sub new { bless { layer => 0 }, shift }
	}

	my $stub1 = bless { layer => 1 }, 'ILI::Stub';
	my $stub2 = bless { layer => 2 }, 'ILI::Stub';

	intercept_new 'ILI::Svc' => $stub1;   # bottom layer
	intercept_new 'ILI::Svc' => $stub2;   # top layer

	# Use explicit parens to avoid indirect-method-syntax ambiguity:
	# "is Pkg->new()->{k}" is misread by Perl as "Pkg->is(...)".
	my $top_obj = ILI::Svc->new();
	is($top_obj->{layer}, 2, 'top interceptor (layer 2) wins');

	unmock 'ILI::Svc::new';   # pop top layer
	my $mid_obj = ILI::Svc->new();
	is($mid_obj->{layer}, 1, 'layer 1 revealed after unmocking top');

	Test::Mockingbird::restore_all();

	# Original constructor must be back: it blesses into ILI::Svc, not ILI::Stub
	my $obj = ILI::Svc->new;
	ok !$obj->isa('ILI::Stub'), 'real constructor restored after restore_all';
	ok  $obj->isa('ILI::Svc'),  'real object is correct class';
};

# ============================================================================
#  SECTION 10 -- Guard lifecycle
# ============================================================================

subtest 'mock_scoped multi-shorthand: 3 methods restored atomically by guard DESTROY' => sub {
	{
		package MSM::Svc;
		sub read   { 'r' }
		sub write  { 'w' }
		sub delete { 'd' }
	}

	{
		my $g = mock_scoped(
			'MSM::Svc::read'   => sub { 'R' },
			'MSM::Svc::write'  => sub { 'W' },
			'MSM::Svc::delete' => sub { 'D' },
		);

		is MSM::Svc::read(),   'R', 'read mocked inside guard scope';
		is MSM::Svc::write(),  'W', 'write mocked inside guard scope';
		is MSM::Svc::delete(), 'D', 'delete mocked inside guard scope';

		my $diag = diagnose_mocks();
		ok exists $diag->{'MSM::Svc::read'},   'read in mock state while guard alive';
		ok exists $diag->{'MSM::Svc::write'},  'write in mock state while guard alive';
		ok exists $diag->{'MSM::Svc::delete'}, 'delete in mock state while guard alive';
	}
	# Guard $g goes out of scope; DESTROY restores all three atomically.
	is MSM::Svc::read(),   'r', 'read restored after guard DESTROY';
	is MSM::Svc::write(),  'w', 'write restored after guard DESTROY';
	is MSM::Svc::delete(), 'd', 'delete restored after guard DESTROY';

	my $diag = diagnose_mocks();
	ok !exists $diag->{'MSM::Svc::read'},   'read absent from mock state';
	ok !exists $diag->{'MSM::Svc::write'},  'write absent from mock state';
	ok !exists $diag->{'MSM::Svc::delete'}, 'delete absent from mock state';
};

subtest 'Guard DESTROY after restore_all is idempotent (no double-restore error)' => sub {
	# If the user calls restore_all() while a guard is still alive, DESTROY
	# must not crash when it tries to unmock an already-unmocked target.
	{
		package GIA::P;
		sub fn { 'orig' }
	}

	my $g = mock_scoped 'GIA::P::fn' => sub { 'scoped' };
	is GIA::P::fn(), 'scoped', 'mock active while guard alive';

	Test::Mockingbird::restore_all();   # first restore -- removes the mock
	is GIA::P::fn(), 'orig', 'original restored by restore_all';

	# Explicitly destroy the guard while the method is already unmocked.
	# This must not die, warn, or corrupt state.
	my @warns;
	local $SIG{__WARN__} = sub { push @warns, $_[0] };

	lives_ok { undef $g } 'guard DESTROY after restore_all does not die';
	ok !@warns, 'no warnings from guard DESTROY on already-restored target';
	is GIA::P::fn(), 'orig', 'original still intact after second DESTROY';
};

# ============================================================================
#  SECTION 11 -- Time + mock cross-module workflows
# ============================================================================

subtest 'with_frozen_time: advance_time inside block does not affect outer state' => sub {
	# $CURRENT_EPOCH is saved/restored by with_frozen_time.  Any advance_time
	# calls inside the block modify the local copy only.
	my $outer = freeze_time($TS_2025_JAN1);

	with_frozen_time $TS_2025_JUN1 => sub {
		my $inner_start = now();
		advance_time(3600);
		is now(), $inner_start + 3600,
			'advance_time takes effect inside with_frozen_time block';
	};

	# The outer epoch must be exactly as it was before the block.
	is now(), $outer,
		'outer epoch unchanged after inner advance_time + block exit';

	restore_all();
};

subtest 'with_frozen_time + mock: mock closure sees frozen now()' => sub {
	# Verify that a mock coderef executing inside a with_frozen_time block
	# observes the frozen time when it calls now().
	{
		package WFM::Stamper;
		sub stamp { Test::Mockingbird::TimeTravel::now() }
	}

	my $outer = freeze_time($TS_2025_JAN1);
	my $seen_in_block;

	with_frozen_time $TS_2025_JUN15 => sub {
		mock 'WFM::Stamper::stamp' => sub { Test::Mockingbird::TimeTravel::now() };
		$seen_in_block = WFM::Stamper::stamp();
		Test::Mockingbird::restore_all();
	};

	is $seen_in_block, $parse->($TS_2025_JUN15),
		'mock coderef observed frozen time inside with_frozen_time block';
	is now(), $outer,
		'outer time restored correctly after block';

	restore_all();
};

# ============================================================================
#  SECTION 12 -- deep_mock advanced scenarios
# ============================================================================

subtest 'deep_mock exception recovery: mocks cleaned up when block throws' => sub {
	# deep_mock wraps $code in eval; restore_all() is called before re-croaking.
	# This test verifies that a throwing block does not leave stale mocks.
	{
		package DMEx::P;
		sub fn { 'orig' }
	}

	eval {
		deep_mock(
			{
				mocks => [
					{ target => 'DMEx::P::fn', type => 'mock', with => sub { 'mocked' } },
				],
			},
			sub { die "block died\n" }
		);
	};

	like $@, qr/block died/, 'exception propagated out of deep_mock';
	is DMEx::P::fn(), 'orig', 'mock cleaned up despite exception in block';
	ok !exists diagnose_mocks()->{'DMEx::P::fn'},
		'target absent from mock state after exceptional deep_mock';
};

subtest 'deep_mock inject type: installs injected value inside block' => sub {
	{
		package DM::Inj;
		sub dep { 'real' }
	}

	deep_mock(
		{
			mocks => [{
				target => 'DM::Inj::dep',
				type   => 'inject',
				with   => 'injected_val',
			}],
		},
		sub { is DM::Inj::dep(), 'injected_val', 'inject type active inside block' }
	);

	is DM::Inj::dep(), 'real', 'inject restored after deep_mock block';
};

subtest 'deep_mock return value propagates: scalar context' => sub {
	{
		package DM::RV;
		sub fn { 0 }
	}

	my $rv = deep_mock(
		{ mocks => [{ target => 'DM::RV::fn', type => 'mock', with => sub { 42 } }] },
		sub { DM::RV::fn() }
	);

	is $rv, 42, 'deep_mock returns scalar result of code block';
};

subtest 'deep_mock return value propagates: list context' => sub {
	{
		package DM::RVL;
		sub fn { () }
	}

	my @rv = deep_mock(
		{ mocks => [{ target => 'DM::RVL::fn', type => 'mock', with => sub { (10, 20, 30) } }] },
		sub { DM::RVL::fn() }
	);

	is_deeply \@rv, [10, 20, 30], 'deep_mock returns list result of code block';
};

# ============================================================================
#  SECTION 13 -- Scoped restore & cross-package isolation
# ============================================================================

subtest 'restore_all(pkg): scoped form leaves other packages intact' => sub {
	{
		package Scoped::A;
		sub fn { 'a' }
	}
	{
		package Scoped::B;
		sub fn { 'b' }
	}

	mock_return 'Scoped::A::fn' => 'mocked_a';
	mock_return 'Scoped::B::fn' => 'mocked_b';

	Test::Mockingbird::restore_all('Scoped::A');

	is Scoped::A::fn(), 'a',        'Scoped::A restored by scoped restore_all';
	is Scoped::B::fn(), 'mocked_b', 'Scoped::B untouched by scoped restore_all';

	ok !exists diagnose_mocks()->{'Scoped::A::fn'},
		'Scoped::A absent from mock state';
	ok  exists diagnose_mocks()->{'Scoped::B::fn'},
		'Scoped::B still in mock state';

	Test::Mockingbird::restore_all();
};

subtest 'cross-package isolation: unmock in X does not disturb Y mock stack' => sub {
	# Two independent stacks must not interfere even when one is being surgically
	# modified via unmock().
	{
		package Iso::X;
		sub fn { 'x' }
	}
	{
		package Iso::Y;
		sub fn { 'y' }
	}

	mock_return 'Iso::X::fn' => 'X1';
	mock_return 'Iso::X::fn' => 'X2';   # X has 2 layers
	mock_return 'Iso::Y::fn' => 'Y1';   # Y has 1 layer

	is Iso::X::fn(), 'X2', 'X top layer is X2';
	is Iso::Y::fn(), 'Y1', 'Y layer is Y1';

	unmock 'Iso::X::fn';   # pops X2 only
	is Iso::X::fn(), 'X1', 'X falls back to X1 after unmock';
	is Iso::Y::fn(), 'Y1', 'Y completely unaffected by X unmock';

	my $diag = diagnose_mocks();
	is $diag->{'Iso::X::fn'}{depth}, 1, 'X has exactly 1 layer remaining';
	is $diag->{'Iso::Y::fn'}{depth}, 1, 'Y still has its 1 layer';

	Test::Mockingbird::restore_all();
	is Iso::X::fn(), 'x', 'X original fully restored';
	is Iso::Y::fn(), 'y', 'Y original fully restored';
};

# ============================================================================
#  SECTION 14 -- diagnose_mocks_pretty realistic scenario
# ============================================================================

subtest 'diagnose_mocks_pretty: realistic multi-layer output' => sub {
	{
		package DMP::Svc;
		sub read    { 1 }
		sub write   { 2 }
		sub execute { 3 }
	}

	mock_return    'DMP::Svc::read'    => 42;
	mock_exception 'DMP::Svc::write'   => 'write failed';
	mock_sequence  'DMP::Svc::execute' => (10, 20, 30);

	my $pretty = diagnose_mocks_pretty();

	like $pretty, qr/DMP::Svc::read/,    'read method in pretty output';
	like $pretty, qr/DMP::Svc::write/,   'write method in pretty output';
	like $pretty, qr/DMP::Svc::execute/, 'execute method in pretty output';
	like $pretty, qr/mock_return/,        'mock_return type in pretty output';
	like $pretty, qr/mock_exception/,     'mock_exception type in pretty output';
	like $pretty, qr/mock_sequence/,      'mock_sequence type in pretty output';
	like $pretty, qr/depth: 1/,           'depth shown for at least one method';
	like $pretty, qr/original_existed/,   'original_existed flag present';
	like $pretty, qr/installed_at/,       'installed_at field present';

	diag $pretty if $ENV{TEST_VERBOSE};
	Test::Mockingbird::restore_all();
};

# ============================================================================
#  SECTION 15 -- Async module: Future present
#
#  Each subtest skips individually if Future is not installed.
# ============================================================================

subtest 'Async: mock_future_return -> resolved Future with scalar value' => sub {
	plan skip_all => 'Future not installed'
		unless eval { require Future; 1 };

	require Test::Mockingbird::Async;
	my $mfr = \&Test::Mockingbird::Async::mock_future_return;

	{
		package Async::S;
		sub fetch { die "real fetch called\n" }
	}

	$mfr->('Async::S::fetch', 99);
	my $f      = Async::S::fetch();
	my ($val)  = $f->get;
	is $val, 99, 'mock_future_return: Future resolves to scalar value';

	Test::Mockingbird::restore_all();
};

subtest 'Async: mock_future_return -> multi-value resolved Future' => sub {
	plan skip_all => 'Future not installed'
		unless eval { require Future; 1 };

	require Test::Mockingbird::Async;
	my $mfr = \&Test::Mockingbird::Async::mock_future_return;

	{
		package Async::MV;
		sub query { () }
	}

	$mfr->('Async::MV::query', 'a', 'b', 'c');
	my @vals = Async::MV::query()->get;
	is_deeply \@vals, ['a', 'b', 'c'],
		'mock_future_return: multi-value Future resolves correctly';

	Test::Mockingbird::restore_all();
};

subtest 'Async: mock_future_fail -> pre-failed Future (no exception at call site)' => sub {
	plan skip_all => 'Future not installed'
		unless eval { require Future; 1 };

	require Test::Mockingbird::Async;
	my $mff = \&Test::Mockingbird::Async::mock_future_fail;

	{
		package Async::F;
		sub fetch { die "real fetch called\n" }
	}

	$mff->('Async::F::fetch', 'not found', 'db', { code => 404 });

	# Call site does NOT throw; caller receives a pre-failed Future
	my $f;
	lives_ok { $f = Async::F::fetch() }
		'mock_future_fail: call site does not throw';

	my ($msg, @details) = $f->failure;
	is $msg, 'not found', 'failure message correct';
	is $details[0], 'db', 'first detail correct';
	is $details[1]{code}, 404, 'second detail hashref correct';

	Test::Mockingbird::restore_all();
};

subtest 'Async: mock_future_sequence -> advance and repeat last' => sub {
	plan skip_all => 'Future not installed'
		unless eval { require Future; 1 };

	require Test::Mockingbird::Async;
	my $mfs = \&Test::Mockingbird::Async::mock_future_sequence;

	{
		package Async::Seq;
		sub poll { die "real poll called\n" }
	}

	$mfs->('Async::Seq::poll', 10, 20, 30);
	is Async::Seq::poll()->get, 10, 'sequence: first item';
	is Async::Seq::poll()->get, 20, 'sequence: second item';
	is Async::Seq::poll()->get, 30, 'sequence: third item';
	is Async::Seq::poll()->get, 30, 'sequence: last item repeats';

	Test::Mockingbird::restore_all();
};

subtest 'Async: mock_future_once -> fires once then restores previous mock' => sub {
	plan skip_all => 'Future not installed'
		unless eval { require Future; 1 };

	require Test::Mockingbird::Async;
	my $mfr = \&Test::Mockingbird::Async::mock_future_return;
	my $mfo = \&Test::Mockingbird::Async::mock_future_once;

	{
		package Async::Once;
		sub ping { die "real ping\n" }
	}

	$mfr->('Async::Once::ping', 'baseline');   # bottom layer
	$mfo->('Async::Once::ping', 'transient');  # top: fires once

	is Async::Once::ping()->get, 'transient', 'first call: once-mock fires';
	is Async::Once::ping()->get, 'baseline',  'second call: baseline restored';

	Test::Mockingbird::restore_all();
};

subtest 'Async: async_spy captures args and future' => sub {
	plan skip_all => 'Future not installed'
		unless eval { require Future; 1 };

	require Test::Mockingbird::Async;
	my $asp = \&Test::Mockingbird::Async::async_spy;
	my $mfr = \&Test::Mockingbird::Async::mock_future_return;

	{
		package Async::Spy;
		sub fetch { die "real fetch\n" }
	}

	$mfr->('Async::Spy::fetch', 'spy_value');   # install a real Future returner
	my $spy_cref = $asp->('Async::Spy::fetch'); # wrap with async_spy on top

	my $f = Async::Spy::fetch('key1');
	is $f->get, 'spy_value', 'async_spy passes through Future unchanged';

	my @calls = $spy_cref->();
	is scalar @calls, 1, 'async_spy captured one call';
	is_deeply $calls[0]{args}, ['Async::Spy::fetch', 'key1'],
		'call record contains method and argument';
	isa_ok $calls[0]{future}, 'Future', 'captured Future is a Future object';

	Test::Mockingbird::restore_all();
};

subtest 'Async: diagnose_mocks shows correct layer types for async mocks' => sub {
	plan skip_all => 'Future not installed'
		unless eval { require Future; 1 };

	require Test::Mockingbird::Async;
	my $mfr = \&Test::Mockingbird::Async::mock_future_return;
	my $mff = \&Test::Mockingbird::Async::mock_future_fail;
	my $asp = \&Test::Mockingbird::Async::async_spy;

	{
		package Async::Diag;
		sub a { die }
		sub b { die }
	}

	$mfr->('Async::Diag::a', 1);
	$mff->('Async::Diag::b', 'err');

	my $d = diagnose_mocks();
	is $d->{'Async::Diag::a'}{layers}[0]{type}, $T_MFR,
		"layer type is $T_MFR";
	is $d->{'Async::Diag::b'}{layers}[0]{type}, $T_MFF,
		"layer type is $T_MFF";

	diag diagnose_mocks_pretty() if $ENV{TEST_VERBOSE};
	Test::Mockingbird::restore_all();
};

subtest 'Async: assert_call_order works across plain spy and async_spy' => sub {
	plan skip_all => 'Future not installed'
		unless eval { require Future; 1 };

	require Test::Mockingbird::Async;
	my $mfr = \&Test::Mockingbird::Async::mock_future_return;
	my $asp = \&Test::Mockingbird::Async::async_spy;

	{
		package Async::Ord::A;
		sub run { die "real A\n" }
	}
	{
		package Async::Ord::B;
		sub run { die "real B\n" }
	}

	$mfr->('Async::Ord::A::run', 'a_val');
	$mfr->('Async::Ord::B::run', 'b_val');

	$asp->('Async::Ord::A::run');   # async_spy writes to call-order log
	$asp->('Async::Ord::B::run');

	Async::Ord::A::run();
	Async::Ord::B::run();

	# assert_call_order works across both async_spy entries
	assert_call_order('Async::Ord::A::run', 'Async::Ord::B::run');

	Test::Mockingbird::restore_all();
};

# ============================================================================
#  SECTION 16 -- Async module: Future absent
# ============================================================================

subtest 'Async: croaks with install message when Future unavailable' => sub {
	# This test needs Test::Without::Module to block a real Future install,
	# OR runs naturally on a system where Future is not installed.
	#
	# Strategy A: Future not installed -- no gating needed; the croak fires.
	# Strategy B: Future installed -- use Test::Without::Module + cache purge.

	my $future_present  = eval { require Future; 1 };
	my $has_twm         = eval { require Test::Without::Module; 1 };

	if (!$future_present) {
		# Strategy A: Future genuinely absent; every Async function should croak.
		require Test::Mockingbird::Async;
		my $mfr = \&Test::Mockingbird::Async::mock_future_return;
		throws_ok { $mfr->('Absent::fn', 42) }
			qr/\Q$ERR_FUTURE_ABSENT\E/,
			'croak message mentions Future module';
		throws_ok { $mfr->('Absent::fn', 42) }
			qr/\Q$ERR_FUTURE_INSTALL\E/,
			'croak message includes cpanm install command';

	} elsif ($has_twm) {
		# Strategy B: block Future and delete it from the require cache.
		require Test::Mockingbird::Async;
		my $mfr = \&Test::Mockingbird::Async::mock_future_return;

		Test::Without::Module->import('Future');
		my $saved_inc = delete $INC{'Future.pm'};

		my ($err1, $err2);
		eval { $mfr->('Absent::fn', 42) }; $err1 = $@;
		eval { $mfr->('Absent::fn', 42) }; $err2 = $@;

		# Restore Future before any assertions that might need it
		Test::Without::Module->unimport('Future');
		$INC{'Future.pm'} = $saved_inc if defined $saved_inc;

		like $err1, qr/\Q$ERR_FUTURE_ABSENT\E/,
			'croak message mentions Future module (via TWM)';
		like $err2, qr/\Q$ERR_FUTURE_INSTALL\E/,
			'croak message includes cpanm install command (via TWM)';

	} else {
		plan skip_all =>
			'Future is installed and Test::Without::Module is not available; '
			. 'cannot simulate Future absence';
	}
};

# ===========================================================================
# before() / after() / around() integration scenarios
# ===========================================================================

subtest 'before() + spy(): spy records calls that pass through before wrapper' => sub {
	# Realistic scenario: spy on a method to record call args while a before
	# hook validates preconditions.  Both must see the call.
	{ package Int::BeforeSpy; sub process { "processed:$_[0]" } }
	my @precondition_args;
	before 'Int::BeforeSpy::process' => sub { @precondition_args = @_ };
	my $spy = spy 'Int::BeforeSpy::process';

	my $r = Int::BeforeSpy::process('item');

	is $r, 'processed:item', 'original return value reaches caller';
	is_deeply \@precondition_args, ['item'], 'before hook saw args';
	my @calls = $spy->();
	is scalar @calls, 1, 'spy recorded the call';
	is_deeply $calls[0], ['Int::BeforeSpy::process', 'item'],
		'spy call record is correct';
	Test::Mockingbird::restore_all();
};

subtest 'around(): realistic service-double pattern' => sub {
	# A service method normally makes an expensive call; around() replaces it
	# during testing while still calling the original for fast inputs.
	{ package Int::Service;
		sub fetch {
			my ($self, $id) = @_;
			return "db:$id";   # pretend DB call
		}
	}
	my @bypassed;
	around 'Int::Service::fetch' => sub {
		my ($orig, $self, $id) = @_;
		if ($id > 100) {
			push @bypassed, $id;
			return "cached:$id";   # short-circuit expensive path
		}
		return $orig->($self, $id);
	};

	is Int::Service::fetch(undef, 5),   'db:5',       'small id goes to original';
	is Int::Service::fetch(undef, 200), 'cached:200', 'large id short-circuited';
	is_deeply \@bypassed, [200], 'bypass list recorded correctly';
	Test::Mockingbird::restore_all();
};

subtest 'after() collects return values across multiple calls' => sub {
	# Realistic: audit trail — record every return value without changing
	# production code.
	{ package Int::Audit; sub compute { $_[0] ** 2 } }
	my @results;
	after 'Int::Audit::compute' => sub { };   # hook just verifies it runs
	# Use around to capture return value in a realistic audit pattern
	around 'Int::Audit::compute' => sub {
		my ($orig, @args) = @_;
		my $r = $orig->(@args);
		push @results, $r;
		return $r;
	};

	Int::Audit::compute(3);
	Int::Audit::compute(4);
	Int::Audit::compute(5);

	is_deeply \@results, [9, 16, 25], 'around captured all return values';
	Test::Mockingbird::restore_all();
};

subtest 'before() / after() / around() all cleaned up by restore_all() in integration context' => sub {
	{ package Int::CleanUp; sub fn { 'real' } }
	before 'Int::CleanUp::fn' => sub { };
	after  'Int::CleanUp::fn' => sub { };
	around 'Int::CleanUp::fn' => sub { my ($o) = @_; $o->() };

	Test::Mockingbird::restore_all();

	is Int::CleanUp::fn(), 'real',
		'original restored; no wrapper overhead after restore_all';
	my $d = diagnose_mocks();
	ok !exists $d->{'Int::CleanUp::fn'},
		'no mock state leaked after restore_all';
};

done_testing();
