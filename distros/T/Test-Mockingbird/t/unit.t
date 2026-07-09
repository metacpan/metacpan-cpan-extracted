#!/usr/bin/env perl

use strict;
use warnings;

use Readonly;
use Test::Most;
use Test::Mockingbird;
use Test::Mockingbird::DeepMock qw(deep_mock);

# Import TimeTravel functions but NOT its restore_all, to avoid shadowing
# the core Test::Mockingbird::restore_all that is used throughout this file.
use Test::Mockingbird::TimeTravel qw(
	now freeze_time travel_to advance_time rewind_time with_frozen_time
);

# ---------------------------------------------------------------------------
# Constants: magic-string elimination for layer types and error messages
# ---------------------------------------------------------------------------

Readonly my $T_MOCK         => 'mock';
Readonly my $T_SPY          => 'spy';
Readonly my $T_INJECT       => 'inject';
Readonly my $T_MOCK_RETURN  => 'mock_return';
Readonly my $T_MOCK_EXCEPT  => 'mock_exception';
Readonly my $T_MOCK_SEQ     => 'mock_sequence';
Readonly my $T_MOCK_ONCE    => 'mock_once';
Readonly my $T_MOCK_SCOPED  => 'mock_scoped';
Readonly my $T_INTERCEPT    => 'intercept_new';

Readonly my $ERR_MOCK      => 'Package, method and replacement are required for mocking';
Readonly my $ERR_UNMOCK    => 'Package and method are required for unmocking';
Readonly my $ERR_SCOPED    => 'mock_scoped: unrecognised argument form';
Readonly my $ERR_SPY       => 'Package and method are required for spying';
Readonly my $ERR_INJECT    => 'Package and dependency are required for injection';
Readonly my $ERR_IA_PKG    => 'inject_all requires a package name';
Readonly my $ERR_IA_HREF   => 'inject_all requires a hashref of dependencies';
Readonly my $ERR_IN_CLASS  => 'intercept_new requires a class name';
Readonly my $ERR_IN_REPL   => 'intercept_new requires a replacement object or coderef';
Readonly my $ERR_RESTORE   => 'restore requires a target';
Readonly my $ERR_MR        => 'mock_return requires a target and a value';
Readonly my $ERR_ME        => 'mock_exception requires a target and an exception message';
Readonly my $ERR_MS        => 'mock_sequence requires a target and at least one value';
Readonly my $ERR_MO        => 'mock_once requires a target and a coderef';
Readonly my $ERR_ACO       => 'assert_call_order requires at least two method names';
Readonly my $ERR_TT_TRAV   => 'travel_to() called while TimeTravel is inactive';
Readonly my $ERR_TT_ADV    => 'advance_time() called while TimeTravel is inactive';
Readonly my $ERR_TT_REW    => 'rewind_time() called while TimeTravel is inactive';
Readonly my $ERR_TT_CODE   => 'with_frozen_time() requires a coderef';
Readonly my $ERR_TT_TS     => 'with_frozen_time() requires a timestamp';

# ============================================================================
#  SECTION 1 -- DeepMock internal helpers (black-box via public interface)
# ============================================================================

subtest '_normalize_target' => sub {
	is_deeply(
		[ Test::Mockingbird::DeepMock::_normalize_target('A::b') ],
		[ 'A', 'b' ],
		'splits Package::method correctly'
	);
	is_deeply(
		[ Test::Mockingbird::DeepMock::_normalize_target('A', 'b') ],
		[ 'A', 'b' ],
		'returns (pkg, method) when given separately'
	);
	is_deeply(
		[ Test::Mockingbird::DeepMock::_normalize_target('Foo::Bar::baz') ],
		[ 'Foo::Bar', 'baz' ],
		'handles multi-level package names'
	);
};

subtest '_install_mocks basic behavior' => sub {
	{
		package UT1;
		our $X = 10;
		sub foo { 'orig' }
		sub bar { $X }
	}

	my %handles;
	my @installed = Test::Mockingbird::DeepMock::_install_mocks(
		[
			{
				target => 'UT1::foo',
				type   => 'mock',
				with   => sub { 'mocked' },
				tag    => 'f',
			},
			{
				target => 'UT1::bar',
				type   => 'spy',
				tag    => 'b',
			},
		],
		\%handles,
	);

	is UT1::foo(), 'mocked', 'mock installed';
	is UT1::bar(), 10,       'spy installed (original behavior preserved)';
	ok $handles{f}{guard},   'mock tag stored';
	ok $handles{b}{spy},     'spy tag stored';
	cmp_ok scalar(@installed), '==', 2, 'two entries returned from _install_mocks';

	Test::Mockingbird::restore_all();
};

subtest '_install_mocks error handling' => sub {
	# Missing target must croak, not silently proceed.
	dies_ok {
		Test::Mockingbird::DeepMock::_install_mocks(
			[ { type => 'mock', with => sub {} } ],
			{}
		);
	} 'missing target dies';

	# Unknown type must croak rather than silently skip.
	dies_ok {
		Test::Mockingbird::DeepMock::_install_mocks(
			[ { target => 'A::b', type => 'wut' } ],
			{}
		);
	} 'unknown type dies';
};

subtest '_run_expectations call count' => sub {
	{
		package UT2;
		sub foo { ($_[1] // 0) * 2 }
	}

	my %handles;
	my $spy = Test::Mockingbird::spy('UT2', 'foo');
	$handles{spy1}{spy} = $spy;

	UT2::foo(10);
	UT2::foo(20);

	Test::Mockingbird::DeepMock::_run_expectations(
		[ { tag => 'spy1', calls => 2 } ],
		\%handles,
	);

	Test::Mockingbird::restore_all();
};

subtest '_run_expectations args_like' => sub {
	{
		package UT3;
		sub foo { $_[1] }
	}

	my %handles;
	my $spy = Test::Mockingbird::spy('UT3', 'foo');
	$handles{s}{spy} = $spy;

	UT3::foo('alpha');
	UT3::foo('beta');

	Test::Mockingbird::DeepMock::_run_expectations(
		[
			{
				tag       => 's',
				args_like => [
					[ qr/^alpha$/ ],
					[ qr/^beta$/  ],
				],
			}
		],
		\%handles,
	);

	Test::Mockingbird::restore_all();
};

subtest '_run_expectations missing tag dies' => sub {
	throws_ok {
		Test::Mockingbird::DeepMock::_run_expectations(
			[ { calls => 1 } ],
			{}
		);
	} qr/expectation missing tag/, 'missing tag dies';
};

subtest '_run_expectations missing spy dies' => sub {
	throws_ok {
		Test::Mockingbird::DeepMock::_run_expectations(
			[ { tag => 'nope', calls => 1 } ],
			{}
		);
	} qr/no spy handle/, 'missing spy handle dies';
};

subtest 'empty mocks and expectations do nothing' => sub {
	lives_ok {
		Test::Mockingbird::DeepMock::_install_mocks([], {});
		Test::Mockingbird::DeepMock::_run_expectations([], {});
	} 'empty arrays are safe';
};

subtest '_run_expectations args_eq' => sub {
	{
		package UT_EQ;
		sub foo { $_[1] }
	}

	my %handles;
	my $spy = Test::Mockingbird::spy('UT_EQ', 'foo');
	$handles{s}{spy} = $spy;

	UT_EQ::foo('x');
	UT_EQ::foo('y');

	Test::Mockingbird::DeepMock::_run_expectations(
		[ { tag => 's', args_eq => [ ['x'], ['y'] ] } ],
		\%handles,
	);

	Test::Mockingbird::restore_all();
};

subtest '_run_expectations args_deeply' => sub {
	{
		package UT_DEEP;
		sub foo { $_[1] }
	}

	my %handles;
	my $spy = Test::Mockingbird::spy('UT_DEEP', 'foo');
	$handles{s}{spy} = $spy;

	UT_DEEP::foo({ a => 1 });
	UT_DEEP::foo({ b => [2,3] });

	Test::Mockingbird::DeepMock::_run_expectations(
		[
			{
				tag        => 's',
				args_deeply => [
					[ { a => 1 } ],
					[ { b => [2,3] } ],
				],
			}
		],
		\%handles,
	);

	Test::Mockingbird::restore_all();
};

subtest '_run_expectations never' => sub {
	{
		package UT_NEVER;
		sub foo { $_[1] }
	}

	my %handles;
	my $spy = Test::Mockingbird::spy('UT_NEVER', 'foo');
	$handles{s}{spy} = $spy;

	# Do not call foo() -- the never expectation must pass.
	Test::Mockingbird::DeepMock::_run_expectations(
		[ { tag => 's', never => 1 } ],
		\%handles,
	);

	Test::Mockingbird::restore_all();
};

subtest '_run_expectations order key delegates to assert_call_order' => sub {
	{
		package UT_ORD_A;
		sub go { 1 }
	}
	{
		package UT_ORD_B;
		sub go { 1 }
	}

	my %handles;
	my $spy_a = Test::Mockingbird::spy('UT_ORD_A', 'go');
	my $spy_b = Test::Mockingbird::spy('UT_ORD_B', 'go');
	$handles{a}{spy} = $spy_a;
	$handles{b}{spy} = $spy_b;

	UT_ORD_A::go();
	UT_ORD_B::go();

	# Should pass: A before B.
	Test::Mockingbird::DeepMock::_run_expectations(
		[
			{ tag => 'a', calls => 1 },
			{ tag => 'b', calls => 1 },
			{ order => [ 'UT_ORD_A::go', 'UT_ORD_B::go' ] },
		],
		\%handles,
	);

	Test::Mockingbird::restore_all();
};

subtest '_run_expectations order-only entry skips tag croak' => sub {
	# An entry with only an order key (no tag) must not trigger
	# "expectation missing tag" in the per-spy loop.
	{
		package UT_ORD_SKIP_A;
		sub run { 1 }
	}
	{
		package UT_ORD_SKIP_B;
		sub run { 1 }
	}

	my $spy_a = Test::Mockingbird::spy('UT_ORD_SKIP_A', 'run');
	my $spy_b = Test::Mockingbird::spy('UT_ORD_SKIP_B', 'run');

	UT_ORD_SKIP_A::run();
	UT_ORD_SKIP_B::run();

	lives_ok {
		Test::Mockingbird::DeepMock::_run_expectations(
			[ { order => [ 'UT_ORD_SKIP_A::run', 'UT_ORD_SKIP_B::run' ] } ],
			{}
		);
	} 'order-only expectation (no tag) does not croak with missing tag';

	Test::Mockingbird::restore_all();
};

# ============================================================================
#  SECTION 2 -- mock() public API
# ============================================================================

subtest 'mock(): shorthand form installs replacement' => sub {
	{ package M::Short; sub fn { 'orig' } }

	my $rv = mock 'M::Short::fn' => sub { 'mocked' };
	ok !defined $rv,         'mock() returns undef (per POD)';
	is M::Short::fn(), 'mocked', 'shorthand mock active';
	restore_all();
};

subtest 'mock(): longhand three-arg form' => sub {
	{ package M::Long; sub fn { 'orig' } }

	mock('M::Long', 'fn', sub { 'longhand' });
	is M::Long::fn(), 'longhand', 'longhand mock active';
	restore_all();
};

subtest 'mock(): mocks stack in LIFO order' => sub {
	# POD: "Mocks stack in LIFO order."
	{ package M::Stack; sub fn { 'orig' } }

	mock 'M::Stack::fn' => sub { 'L1' };
	mock 'M::Stack::fn' => sub { 'L2' };
	is M::Stack::fn(), 'L2', 'top (L2) active';

	unmock 'M::Stack::fn';
	is M::Stack::fn(), 'L1', 'L1 exposed after popping L2';

	unmock 'M::Stack::fn';
	is M::Stack::fn(), 'orig', 'original restored after popping L1';
	restore_all();
};

subtest 'mock(): croaks when package missing' => sub {
	throws_ok { mock(undef, 'fn', sub {}) }
		qr/\Q$ERR_MOCK\E/, 'undef package croaks';
};

subtest 'mock(): croaks when method missing' => sub {
	throws_ok { mock('Pkg', undef, sub {}) }
		qr/\Q$ERR_MOCK\E/, 'undef method croaks';
};

subtest 'mock(): croaks when replacement missing' => sub {
	throws_ok { mock('Pkg', 'fn', undef) }
		qr/\Q$ERR_MOCK\E/, 'undef replacement croaks';
};

subtest 'mock(): original_existed=1 for pre-existing method' => sub {
	{ package M::Existed; sub fn { 1 } }

	mock 'M::Existed::fn' => sub { 2 };
	my $d = diagnose_mocks();
	is $d->{'M::Existed::fn'}{layers}[0]{original_existed}, 1,
		'original_existed=1 when method pre-existed';
	restore_all();
};

subtest 'mock(): original_existed=0 for newly-created method' => sub {
	# POD: the existence flag is captured before the first mock is installed.
	mock 'M::Ghost::phantom' => sub { 'x' };
	my $d = diagnose_mocks();
	is $d->{'M::Ghost::phantom'}{layers}[0]{original_existed}, 0,
		'original_existed=0 when method did not exist before mocking';
	restore_all();
};

# ============================================================================
#  SECTION 3 -- unmock()
# ============================================================================

subtest 'unmock(): shorthand restores one layer' => sub {
	{ package UM::S; sub fn { 'orig' } }

	mock 'UM::S::fn' => sub { 'A' };
	unmock 'UM::S::fn';
	is UM::S::fn(), 'orig', 'shorthand unmock restores';
	restore_all();
};

subtest 'unmock(): longhand restores one layer' => sub {
	{ package UM::L; sub fn { 'orig' } }

	mock('UM::L', 'fn', sub { 'B' });
	unmock('UM::L', 'fn');
	is UM::L::fn(), 'orig', 'longhand unmock restores';
	restore_all();
};

subtest 'unmock(): returns undef' => sub {
	{ package UM::Ret; sub fn { 1 } }

	mock 'UM::Ret::fn' => sub { 2 };
	my $rv = unmock 'UM::Ret::fn';
	ok !defined $rv, 'unmock() returns undef (per POD)';
	restore_all();
};

subtest 'unmock(): no-op when method was never mocked' => sub {
	{ package UM::Clean; sub fn { 'orig' } }

	lives_ok { unmock 'UM::Clean::fn' }
		'unmock on clean method is a no-op (does not die)';
	is UM::Clean::fn(), 'orig', 'original untouched';
};

subtest 'unmock(): croaks when target is missing' => sub {
	throws_ok { unmock(undef) }
		qr/\Q$ERR_UNMOCK\E/, 'undef target croaks';
};

subtest 'unmock(): pops only ONE meta entry per call' => sub {
	# A critical regression guard: an earlier bug deleted the entire meta key
	# on every unmock, wiping metadata for lower layers still on the stack.
	{ package UM::Meta; sub fn { 'orig' } }

	mock 'UM::Meta::fn' => sub { 'L1' };
	mock 'UM::Meta::fn' => sub { 'L2' };
	unmock 'UM::Meta::fn';

	my $d = diagnose_mocks();
	is $d->{'UM::Meta::fn'}{depth}, 1, 'one layer remains on stack';
	is scalar @{ $d->{'UM::Meta::fn'}{layers} }, 1,
		'exactly one meta entry (not zero, not two)';
	restore_all();
};

# ============================================================================
#  SECTION 4 -- mock_scoped() and Test::Mockingbird::Guard
# ============================================================================

subtest 'mock_scoped(): shorthand 2-arg form restores on DESTROY' => sub {
	{ package MS::S; sub fn { 'orig' } }

	{
		my $g = mock_scoped 'MS::S::fn' => sub { 'scoped' };
		isa_ok $g, 'Test::Mockingbird::Guard';
		is MS::S::fn(), 'scoped', 'mock active inside block';
	}
	is MS::S::fn(), 'orig', 'mock removed after guard destroyed';
};

subtest 'mock_scoped(): longhand 3-arg form' => sub {
	{ package MS::L; sub fn { 'orig' } }

	{
		my $g = mock_scoped('MS::L', 'fn', sub { 'longhand' });
		is MS::L::fn(), 'longhand', 'longhand mock active';
	}
	is MS::L::fn(), 'orig', 'restored after guard DESTROY';
};

subtest 'mock_scoped(): multi shorthand (even-arg pairs)' => sub {
	{
		package MS::Multi::A;
		sub fn { 'a' }
	}
	{
		package MS::Multi::B;
		sub fn { 'b' }
	}

	{
		my $g = mock_scoped(
			'MS::Multi::A::fn' => sub { 'A' },
			'MS::Multi::B::fn' => sub { 'B' },
		);
		is MS::Multi::A::fn(), 'A', 'first mock active';
		is MS::Multi::B::fn(), 'B', 'second mock active';
	}
	is MS::Multi::A::fn(), 'a', 'first restored';
	is MS::Multi::B::fn(), 'b', 'second restored';
};

subtest 'mock_scoped(): multi longhand (package + method/code pairs)' => sub {
	{
		package MS::ML;
		sub fetch { 'fetch' }
		sub save  { 'save'  }
	}

	{
		my $g = mock_scoped('MS::ML',
			fetch => sub { 'F' },
			save  => sub { 'S' },
		);
		is MS::ML::fetch(), 'F', 'fetch mocked';
		is MS::ML::save(),  'S', 'save mocked';
	}
	is MS::ML::fetch(), 'fetch', 'fetch restored';
	is MS::ML::save(),  'save',  'save restored';
};

subtest 'mock_scoped(): records type mock_scoped in meta' => sub {
	{ package MS::Type; sub fn { 1 } }

	my $g = mock_scoped 'MS::Type::fn' => sub { 2 };
	my $d = diagnose_mocks();
	is $d->{'MS::Type::fn'}{layers}[0]{type}, $T_MOCK_SCOPED,
		'layer type is mock_scoped (not mock)';
};

subtest 'mock_scoped(): croaks on unrecognised argument form' => sub {
	# POD message: "mock_scoped: unrecognised argument form"
	throws_ok { mock_scoped('Only::One') }
		qr/\Q$ERR_SCOPED\E/, 'single non-CODE arg croaks';
};

subtest 'mock_scoped(): croaks when coderef expected but non-CODE given' => sub {
	# Multi-shorthand form: first pair has CODE (to enter that branch), second
	# pair has a non-CODE -- the inner loop must croak with the specific message.
	{ package MS::BadCode; sub fn1 { 1 } sub fn2 { 2 } }
	throws_ok {
		mock_scoped(
			'MS::BadCode::fn1' => sub { 'ok' },
			'MS::BadCode::fn2' => 'not_a_coderef',
		);
	} qr/expected coderef for 'MS::BadCode::fn2'/,
		'non-CODE value in multi-shorthand pair croaks with target name';
};

# ============================================================================
#  SECTION 5 -- spy()
# ============================================================================

subtest 'spy(): returns coderef yielding per-call records' => sub {
	# POD: "Returns a coderef that, when invoked, returns the list of captured
	# call records. Each record is an arrayref [ $full_method, @args ]."
	{ package Spy::P; sub greet { "hello $_[0]" } }

	my $spy = spy 'Spy::P::greet';
	Spy::P::greet('world');
	Spy::P::greet('Perl');

	my @calls = $spy->();
	is scalar @calls, 2, 'two records captured';
	is_deeply $calls[0], [ 'Spy::P::greet', 'world' ], 'first call record correct';
	is_deeply $calls[1], [ 'Spy::P::greet', 'Perl'  ], 'second call record correct';

	restore_all();
};

subtest 'spy(): original method is still called, return value preserved' => sub {
	# POD: "The original method is still called and its return value is passed
	# back to the caller."
	{ package Spy::RT; sub double { $_[0] * 2 } }

	spy 'Spy::RT::double';
	is Spy::RT::double(21), 42, 'original return value passes through spy';
	restore_all();
};

subtest 'spy(): appends to call-order log' => sub {
	{
		package Spy::Log;
		sub a { 1 }
		sub b { 2 }
	}
	spy 'Spy::Log::a';
	spy 'Spy::Log::b';
	Spy::Log::a();
	Spy::Log::b();

	my $ok;
	{
		local $TODO = 'whitebox call-order assertion';
		$ok = assert_call_order('Spy::Log::a', 'Spy::Log::b');
	}
	ok $ok, 'spy appends to call-order log';
	restore_all();
};

subtest 'spy(): croaks when target missing' => sub {
	throws_ok { spy(undef) }
		qr/\Q$ERR_SPY\E/, 'undef target croaks';
};

# ============================================================================
#  SECTION 6 -- inject() and inject_all()
# ============================================================================

subtest 'inject(): shorthand Pkg::dep => value' => sub {
	{ package Inj::S; sub dep { 'real' } }

	inject 'Inj::S::dep' => 'mock_val';
	is Inj::S::dep(), 'mock_val', 'shorthand inject active';
	restore_all();
};

subtest 'inject(): longhand pkg, dep, value' => sub {
	{ package Inj::L; sub dep { 'real' } }

	inject('Inj::L', 'dep', 'longhand_val');
	is Inj::L::dep(), 'longhand_val', 'longhand inject active';
	restore_all();
};

subtest 'inject(): undef is a valid injected value' => sub {
	# POD: "Injecting undef is valid; use argument count (not definedness of
	# the third argument) to distinguish shorthand from longhand."
	{ package Inj::U; sub dep { 'real' } }

	inject('Inj::U', 'dep', undef);
	ok !defined Inj::U::dep(), 'undef injected correctly';
	restore_all();
};

subtest 'inject(): records layer type inject in meta' => sub {
	{ package Inj::D; sub dep { 1 } }

	inject 'Inj::D::dep' => 2;
	my $d = diagnose_mocks();
	is $d->{'Inj::D::dep'}{layers}[0]{type}, $T_INJECT, 'type is inject';
	restore_all();
};

subtest 'inject(): croaks when package missing' => sub {
	throws_ok { inject(undef, 'dep', 'v') }
		qr/\Q$ERR_INJECT\E/, 'undef package croaks';
};

subtest 'inject(): croaks when dependency missing' => sub {
	throws_ok { inject('Pkg', undef, 'v') }
		qr/\Q$ERR_INJECT\E/, 'undef dependency croaks';
};

subtest 'inject_all(): injects all hashref pairs' => sub {
	{ package IA::P; sub db { 'db' } sub cache { 'cache' } }

	inject_all('IA::P', { db => 'mock_db', cache => 'mock_cache' });
	is IA::P::db(),    'mock_db',    'db injected';
	is IA::P::cache(), 'mock_cache', 'cache injected';
	restore_all();
};

subtest 'inject_all(): empty hashref is a no-op' => sub {
	# POD: "An empty hashref is a no-op."
	lives_ok { inject_all('SomePkg', {}) } 'empty hashref does not die';
	my $d = diagnose_mocks();
	ok !keys %$d, 'no mock state created';
};

subtest 'inject_all(): croaks when package is undef' => sub {
	throws_ok { inject_all(undef, {}) }
		qr/\Q$ERR_IA_PKG\E/, 'undef package croaks';
};

subtest 'inject_all(): croaks when package is empty string' => sub {
	throws_ok { inject_all('', {}) }
		qr/\Q$ERR_IA_PKG\E/, 'empty-string package croaks';
};

subtest 'inject_all(): croaks when second arg is not a hashref' => sub {
	throws_ok { inject_all('Pkg', []) }
		qr/\Q$ERR_IA_HREF\E/, 'arrayref instead of hashref croaks';
};

# ============================================================================
#  SECTION 7 -- intercept_new()
# ============================================================================

subtest 'intercept_new(): plain scalar value returned on every call' => sub {
	# POD: "When given a plain value … every call to new returns that value."
	{ package IN::Plain; sub new { bless {}, shift } }

	my $stub = bless {}, 'Stub';
	intercept_new 'IN::Plain' => $stub;
	my $obj = IN::Plain->new;
	is $obj, $stub, 'stub object returned';
	restore_all();
};

subtest 'intercept_new(): coderef factory receives class and original args' => sub {
	# POD: "every call invokes the coderef with the original arguments
	# (including the class name as the first argument)"
	{ package IN::Fact; sub new { bless {}, shift } }

	my @recv;
	intercept_new 'IN::Fact' => sub { @recv = @_; bless {}, 'IN::Double' };
	IN::Fact->new(key => 'val');
	is $recv[0], 'IN::Fact', 'class name forwarded as first arg';
	is $recv[1], 'key',      'additional args forwarded';
	restore_all();
};

subtest 'intercept_new(): undef factory is valid' => sub {
	{ package IN::Undef; sub new { bless {}, shift } }

	intercept_new 'IN::Undef' => undef;
	ok !defined IN::Undef->new, 'undef returned from intercepted new()';
	restore_all();
};

subtest 'intercept_new(): records type intercept_new in meta' => sub {
	{ package IN::Meta; sub new { bless {}, shift } }

	intercept_new 'IN::Meta' => 'stub';
	my $d = diagnose_mocks();
	is $d->{'IN::Meta::new'}{layers}[0]{type}, $T_INTERCEPT,
		'type is intercept_new';
	restore_all();
};

subtest 'intercept_new(): croaks when class is undef' => sub {
	throws_ok { intercept_new(undef, 'stub') }
		qr/\Q$ERR_IN_CLASS\E/, 'undef class croaks';
};

subtest 'intercept_new(): croaks when class is empty string' => sub {
	throws_ok { intercept_new('', 'stub') }
		qr/\Q$ERR_IN_CLASS\E/, 'empty-string class croaks';
};

subtest 'intercept_new(): croaks when factory argument is missing' => sub {
	# POD uses @_ < 2 to detect a truly absent second arg (distinct from undef).
	throws_ok { intercept_new('SomeClass') }
		qr/\Q$ERR_IN_REPL\E/, 'missing factory arg croaks';
};

# ============================================================================
#  SECTION 8 -- restore_all() and restore()
# ============================================================================

subtest 'restore_all(): global form restores all mocks' => sub {
	{
		package RA::A;
		sub fn { 'a' }
		package RA::B;
		sub fn { 'b' }
	}
	mock 'RA::A::fn' => sub { 'A_mocked' };
	mock 'RA::B::fn' => sub { 'B_mocked' };
	restore_all();
	is RA::A::fn(), 'a', 'A restored';
	is RA::B::fn(), 'b', 'B restored';
	my $d = diagnose_mocks();
	is_deeply $d, {}, 'diagnose_mocks returns empty after restore_all';
};

subtest 'restore_all(): scoped form restores only the named package' => sub {
	{
		package RA::Scope::P;
		sub fn { 'p' }
		package RA::Scope::Q;
		sub fn { 'q' }
	}
	mock 'RA::Scope::P::fn' => sub { 'P_mocked' };
	mock 'RA::Scope::Q::fn' => sub { 'Q_mocked' };
	restore_all('RA::Scope::P');
	is RA::Scope::P::fn(), 'p',        'P restored by scoped restore_all';
	is RA::Scope::Q::fn(), 'Q_mocked', 'Q untouched';
	restore_all();
};

subtest 'restore_all(): scoped form prunes call-log for the package' => sub {
	# POD: "The call-order log is pruned to remove entries for the restored
	# package."
	{
		package RA::Log::X;
		sub fn { 1 }
		package RA::Log::Y;
		sub fn { 2 }
	}
	spy 'RA::Log::X::fn';
	spy 'RA::Log::Y::fn';
	RA::Log::X::fn();
	RA::Log::Y::fn();

	restore_all('RA::Log::X');

	# After pruning X's entries, assert_call_order looking for X should fail.
	my $x_found;
	{
		local $TODO = 'call log pruning check';
		$x_found = assert_call_order('RA::Log::X::fn', 'RA::Log::Y::fn');
	}
	ok !$x_found, 'X::fn entries pruned from call log';
	restore_all();
};

subtest 'restore_all(): no-op on clean state' => sub {
	lives_ok { restore_all() }            'global restore on empty state';
	lives_ok { restore_all('NoSuch::Pkg') } 'scoped restore on unknown package';
};

subtest 'restore(): drains all layers for a single target' => sub {
	{ package Rst::P; sub fn { 'orig' } }

	mock 'Rst::P::fn' => sub { 'L1' };
	mock 'Rst::P::fn' => sub { 'L2' };
	restore 'Rst::P::fn';
	is Rst::P::fn(), 'orig', 'all layers removed to original';

	my $d = diagnose_mocks();
	ok !exists $d->{'Rst::P::fn'}, 'entry absent from diagnose_mocks';
};

subtest 'restore(): no-op when method was never mocked' => sub {
	{ package Rst::Clean; sub fn { 'orig' } }
	lives_ok { restore 'Rst::Clean::fn' } 'restore on unmocked method is safe';
	is Rst::Clean::fn(), 'orig', 'method unaffected';
};

subtest 'restore(): croaks on undef target' => sub {
	throws_ok { restore(undef) }
		qr/\Q$ERR_RESTORE\E/, 'undef target croaks';
};

# ============================================================================
#  SECTION 9 -- mock_return(), mock_exception(), mock_sequence(), mock_once()
# ============================================================================

subtest 'mock_return stacks with mock' => sub {
	{ package Edge::Target; sub a { 'orig' } }

	mock_return 'Edge::Target::a' => 'first';
	mock 'Edge::Target::a' => sub { 'second' };
	is Edge::Target::a(), 'second', 'top mock wins';
	restore_all();
};

subtest 'mock_return(): records type mock_return in meta' => sub {
	{ package MR::Type; sub fn { 1 } }

	mock_return 'MR::Type::fn' => 42;
	my $d = diagnose_mocks();
	is $d->{'MR::Type::fn'}{layers}[0]{type}, $T_MOCK_RETURN,
		'type is mock_return';
	restore_all();
};

subtest 'mock_return(): returns fixed value on every call' => sub {
	{ package MR::Val; sub fn { 'orig' } }

	mock_return 'MR::Val::fn' => 99;
	is MR::Val::fn(), 99, 'first call';
	is MR::Val::fn(), 99, 'second call';
	is MR::Val::fn(), 99, 'third call';
	restore_all();
};

subtest 'mock_return(): croaks when target is undef' => sub {
	throws_ok { mock_return(undef, 42) }
		qr/\Q$ERR_MR\E/, 'undef target croaks';
};

subtest 'mock_exception(): throws exact message on every call' => sub {
	{ package ME::P; sub fn { 'orig' } }

	mock_exception 'ME::P::fn' => 'kaboom';
	throws_ok { ME::P::fn() } qr/kaboom/, 'first call throws';
	throws_ok { ME::P::fn() } qr/kaboom/, 'second call still throws';
	restore_all();
};

subtest 'mock_exception(): records type mock_exception in meta' => sub {
	{ package ME::Type; sub fn { 1 } }

	mock_exception 'ME::Type::fn' => 'err';
	my $d = diagnose_mocks();
	is $d->{'ME::Type::fn'}{layers}[0]{type}, $T_MOCK_EXCEPT,
		'type is mock_exception';
	restore_all();
};

subtest 'mock_exception(): croaks when target missing' => sub {
	throws_ok { mock_exception(undef, 'msg') }
		qr/\Q$ERR_ME\E/, 'undef target croaks';
};

subtest 'mock_exception(): croaks when message missing' => sub {
	throws_ok { mock_exception('Pkg::fn', undef) }
		qr/\Q$ERR_ME\E/, 'undef message croaks';
};

subtest 'mock_sequence with restore_all' => sub {
	{ package Edge::Target; sub b { 'orig' } }

	mock_sequence 'Edge::Target::b' => (1, 2);
	is Edge::Target::b(), 1, 'first';
	is Edge::Target::b(), 2, 'second';
	restore_all();
	is Edge::Target::b(), 'orig', 'restore_all restores original';
};

subtest 'mock_sequence(): advances through values, repeats last' => sub {
	{ package MS::P; sub fn { 'orig' } }

	mock_sequence 'MS::P::fn' => (10, 20, 30);
	is MS::P::fn(), 10, 'first value';
	is MS::P::fn(), 20, 'second value';
	is MS::P::fn(), 30, 'third value';
	is MS::P::fn(), 30, 'repeats last value';
	restore_all();
};

subtest 'mock_sequence(): single-value sequence repeats indefinitely' => sub {
	{ package MS::One; sub fn { 'orig' } }

	mock_sequence 'MS::One::fn' => ('only');
	is MS::One::fn(), 'only', 'first call';
	is MS::One::fn(), 'only', 'second call';
	restore_all();
};

subtest 'mock_sequence(): records type mock_sequence in meta' => sub {
	{ package MSQ::Type; sub fn { 1 } }

	mock_sequence 'MSQ::Type::fn' => (1, 2);
	my $d = diagnose_mocks();
	is $d->{'MSQ::Type::fn'}{layers}[0]{type}, $T_MOCK_SEQ,
		'type is mock_sequence';
	restore_all();
};

subtest 'mock_sequence(): croaks when sequence is empty' => sub {
	throws_ok { mock_sequence('Pkg::fn') }
		qr/\Q$ERR_MS\E/, 'empty sequence croaks';
};

subtest 'mock_once stacks correctly' => sub {
	{ package Edge::Target; sub c { 'orig' } }

	mock_return 'Edge::Target::c' => 'first';
	mock_once   'Edge::Target::c' => sub { 'once' };
	is Edge::Target::c(), 'once',  'mock_once fires first';
	is Edge::Target::c(), 'first', 'then previous mock restored';
	restore_all();
};

subtest 'mock_once(): fires exactly once then restores' => sub {
	{ package MO::P; sub fn { 'orig' } }

	mock_once 'MO::P::fn' => sub { 'once_val' };
	is MO::P::fn(), 'once_val', 'first call uses mock';
	is MO::P::fn(), 'orig',     'second call uses original';
	restore_all();
};

subtest 'mock_once(): list context: all return values propagated' => sub {
	# POD: "wantarray ? @result : $result[0]"
	{ package MO::Ctx; sub fn { (1, 2, 3) } }

	mock_once 'MO::Ctx::fn' => sub { (10, 20, 30) };
	my @list = MO::Ctx::fn();
	is_deeply \@list, [10, 20, 30], 'list context: all values returned';
	restore_all();
};

subtest 'mock_once(): scalar context: first element returned' => sub {
	{ package MO::Sc; sub fn { (1, 2, 3) } }

	mock_once 'MO::Sc::fn' => sub { (10, 20, 30) };
	my $scalar = MO::Sc::fn();
	is $scalar, 10, 'scalar context: first element';
	restore_all();
};

subtest 'mock_once(): records type mock_once in meta' => sub {
	{ package MO::Type; sub fn { 1 } }

	mock_once 'MO::Type::fn' => sub { 2 };
	my $d = diagnose_mocks();
	is $d->{'MO::Type::fn'}{layers}[0]{type}, $T_MOCK_ONCE,
		'type is mock_once';
	restore_all();
};

subtest 'mock_once(): croaks when target is undef' => sub {
	throws_ok { mock_once(undef, sub {}) }
		qr/\Q$ERR_MO\E/, 'undef target croaks';
};

subtest 'mock_once(): croaks when replacement is not a coderef' => sub {
	throws_ok { mock_once('Pkg::fn', 'not_code') }
		qr/\Q$ERR_MO\E/, 'non-CODE replacement croaks';
};

# ============================================================================
#  SECTION 10 -- assert_call_order() and clear_call_log()
# ============================================================================

subtest 'assert_call_order(): passes when methods called in declared order' => sub {
	{
		package ACO::P;
		sub a { 1 }
		sub b { 2 }
	}
	spy 'ACO::P::a';
	spy 'ACO::P::b';
	ACO::P::a();
	ACO::P::b();

	my $ok;
	{
		local $TODO = 'call order assertion';
		$ok = assert_call_order('ACO::P::a', 'ACO::P::b');
	}
	ok $ok, 'returns true when order is correct';
	restore_all();
};

subtest 'assert_call_order(): intervening calls are ignored' => sub {
	{
		package ACO::I;
		sub a { 1 }
		sub z { 9 }
		sub b { 2 }
	}
	spy 'ACO::I::a';
	spy 'ACO::I::z';
	spy 'ACO::I::b';
	ACO::I::a();
	ACO::I::z();   # intervening call -- must be ignored per POD
	ACO::I::b();

	my $ok;
	{
		local $TODO = 'call order with intervening call';
		$ok = assert_call_order('ACO::I::a', 'ACO::I::b');
	}
	ok $ok, 'intervening call does not break assertion';
	restore_all();
};

subtest 'assert_call_order(): returns false when order is wrong' => sub {
	{
		package ACO::F;
		sub a { 1 }
		sub b { 2 }
	}
	spy 'ACO::F::a';
	spy 'ACO::F::b';
	ACO::F::b();   # B before A -- wrong order
	ACO::F::a();

	my $ok;
	{
		local $TODO = 'deliberate order failure';
		$ok = assert_call_order('ACO::F::a', 'ACO::F::b');
	}
	ok !$ok, 'returns false when order is wrong';
	restore_all();
};

subtest 'assert_call_order(): croaks with fewer than two names' => sub {
	throws_ok { assert_call_order('Only::One') }
		qr/\Q$ERR_ACO\E/, 'fewer than two names croaks';
};

subtest 'clear_call_log(): empties the log without touching mocks' => sub {
	{ package CCL::P; sub fn { 1 } }
	spy 'CCL::P::fn';
	CCL::P::fn();
	clear_call_log();

	# Log is empty, so an order assertion requiring two entries must fail.
	my $ok;
	{
		local $TODO = 'log should be empty after clear';
		$ok = assert_call_order('CCL::P::fn', 'CCL::P::fn');
	}
	ok !$ok, 'call log empty after clear_call_log';

	# The spy is still installed -- mock state untouched by clear_call_log.
	my $d = diagnose_mocks();
	ok exists $d->{'CCL::P::fn'}, 'spy still in diagnose_mocks after clear';
	restore_all();
};

# ============================================================================
#  SECTION 11 -- diagnose_mocks() and diagnose_mocks_pretty()
# ============================================================================

subtest 'mock_return stacks with diagnose: tracks stacked layers' => sub {
	{ package DM::U1; sub b { 1 } }

	mock_return    'DM::U1::b' => 10;
	mock_exception 'DM::U1::b' => 'boom';

	my $diag = diagnose_mocks();
	is $diag->{'DM::U1::b'}{depth}, 2, 'two layers recorded';

	my @types = map $_->{type}, @{ $diag->{'DM::U1::b'}{layers} };
	is_deeply \@types, [ $T_MOCK_RETURN, $T_MOCK_EXCEPT ], 'types in order';

	restore_all();
};

subtest 'diagnose_mocks(): returns empty hashref when no mocks active' => sub {
	restore_all();
	my $d = diagnose_mocks();
	is ref $d, 'HASH', 'returns a hashref';
	is_deeply $d, {}, 'empty when state is clean';
};

subtest 'diagnose_mocks(): installed_at contains file and line' => sub {
	{ package DM::AT; sub fn { 1 } }

	my $line = __LINE__ + 1;
	mock_return 'DM::AT::fn' => 42;
	my $d = diagnose_mocks();
	like $d->{'DM::AT::fn'}{layers}[0]{installed_at}, qr/unit\.t/,
		'installed_at names this test file';
	like $d->{'DM::AT::fn'}{layers}[0]{installed_at}, qr/line $line/,
		'installed_at has correct line number';
	restore_all();
};

subtest 'diagnose_mocks_pretty(): contains key fields for each layer' => sub {
	{ package DMP::P; sub fn { 1 } }

	mock_return 'DMP::P::fn' => 99;
	my $out = diagnose_mocks_pretty();

	like $out, qr/DMP::P::fn/,       'method name present';
	like $out, qr/depth: 1/,         'depth field present';
	like $out, qr/original_existed/, 'original_existed field present';
	like $out, qr/type: mock_return/, 'type label present';
	like $out, qr/installed_at:/,    'installed_at field present';
	restore_all();
};

subtest 'restore unwinds stacked mocks' => sub {
	{ package Edge::Restore; sub b { 'orig' } }

	mock_return 'Edge::Restore::b' => 'layer1';
	mock_return 'Edge::Restore::b' => 'layer2';
	is Edge::Restore::b(), 'layer2', 'top layer active';
	restore 'Edge::Restore::b';
	is Edge::Restore::b(), 'orig', 'all layers removed';
	restore_all();
};

# ============================================================================
#  SECTION 12 -- Global state integrity
# ============================================================================

subtest 'mock()/unmock() do not clobber $@' => sub {
	# If a caller has an active eval error in $@, mock and unmock must not
	# silently clear it.
	{ package GS::Err; sub fn { 1 } }

	eval { die "pre-existing error\n" };
	my $orig_err = $@;

	mock 'GS::Err::fn' => sub { 2 };
	is $@, $orig_err, 'mock() did not clobber $@';

	unmock 'GS::Err::fn';
	is $@, $orig_err, 'unmock() did not clobber $@';
};

subtest 'restore_all() does not clobber $@' => sub {
	{ package GS::RA; sub fn { 1 } }

	mock 'GS::RA::fn' => sub { 2 };
	eval { die "saved error\n" };
	my $saved = $@;

	restore_all();
	is $@, $saved, 'restore_all() did not clobber $@';
};

subtest 'inject() does not clobber $@' => sub {
	{ package GS::Inj; sub dep { 1 } }

	eval { die "inject test error\n" };
	my $saved = $@;

	inject 'GS::Inj::dep' => 'mock';
	is $@, $saved, 'inject() did not clobber $@';
	restore_all();
};

subtest 'spy() does not clobber $_' => sub {
	{ package GS::Spy; sub fn { 1 } }

	local $_ = 'original dollar underscore';
	spy 'GS::Spy::fn';
	is $_, 'original dollar underscore', 'spy() did not modify $_';
	restore_all();
};

# ============================================================================
#  SECTION 13 -- Prototype preservation
# ============================================================================

subtest 'mock() stamps () prototype onto replacement coderef' => sub {
	{
		package Proto::Unit::NoArgs;
		sub detect () { 'real' }
	}

	mock 'Proto::Unit::NoArgs::detect' => sub { 'mocked' };

	is prototype(\&Proto::Unit::NoArgs::detect), '',
		'() prototype stamped onto replacement';

	restore_all();
};

subtest 'mock() stamps ($$) prototype onto replacement coderef' => sub {
	{
		package Proto::Unit::TwoArgs;
		sub add ($$) { $_[0] + $_[1] }
	}

	mock 'Proto::Unit::TwoArgs::add' => sub { 99 };

	is prototype(\&Proto::Unit::TwoArgs::add), '$$',
		'$$ prototype stamped onto replacement';

	restore_all();
};

subtest 'mock() stamps ($) prototype onto replacement coderef' => sub {
	{
		package Proto::Unit::OneArg;
		sub wrap ($) { "[$_[0]]" }
	}

	mock 'Proto::Unit::OneArg::wrap' => sub { 'wrapped' };

	is prototype(\&Proto::Unit::OneArg::wrap), '$',
		'$ prototype stamped onto replacement';

	restore_all();
};

subtest 'mock() does not impose a prototype when original has none' => sub {
	{
		package Proto::Unit::Plain;
		sub greet { 'hello' }
	}

	mock 'Proto::Unit::Plain::greet' => sub { 'hi' };

	ok !defined prototype(\&Proto::Unit::Plain::greet),
		'no prototype imposed on replacement when original had none';

	restore_all();
};

subtest 'prototype correctly restored after unmock' => sub {
	{
		package Proto::Unit::Restore;
		sub fn () { 'orig' }
	}

	is prototype(\&Proto::Unit::Restore::fn), '',
		'original has () prototype before mocking';

	mock 'Proto::Unit::Restore::fn' => sub { 'mocked' };

	is prototype(\&Proto::Unit::Restore::fn), '',
		'replacement carries () prototype during mock window';

	unmock 'Proto::Unit::Restore::fn';

	is prototype(\&Proto::Unit::Restore::fn), '',
		'original () prototype intact after unmock';
};

subtest 'prototype correct across stacked mocks' => sub {
	{
		package Proto::Unit::Stack;
		sub fn () { 'orig' }
	}

	mock 'Proto::Unit::Stack::fn' => sub { 'L1' };
	is prototype(\&Proto::Unit::Stack::fn), '',
		'L1 replacement carries () prototype';

	mock 'Proto::Unit::Stack::fn' => sub { 'L2' };
	is prototype(\&Proto::Unit::Stack::fn), '',
		'L2 replacement carries () prototype';

	unmock 'Proto::Unit::Stack::fn';
	is prototype(\&Proto::Unit::Stack::fn), '',
		'L1 still carries () prototype after popping L2';

	restore_all();
	is prototype(\&Proto::Unit::Stack::fn), '',
		'original () prototype restored after restore_all';
};

# ============================================================================
#  SECTION 14 -- Test::Mockingbird::TimeTravel public API
# ============================================================================

subtest 'now(): returns CORE::time() when TimeTravel is inactive' => sub {
	# POD: "Returns $CURRENT_EPOCH when frozen, CORE::time() otherwise."
	Test::Mockingbird::TimeTravel::restore_all();
	cmp_ok abs(now() - CORE::time()), '<', 3,
		'now() tracks real time when inactive';
};

subtest 'now(): returns frozen epoch when active' => sub {
	my $frozen = freeze_time('2025-01-01T00:00:00Z');
	is now(), $frozen, 'now() returns frozen epoch';
	Test::Mockingbird::TimeTravel::restore_all();
};

subtest 'freeze_time(): sets $ACTIVE, $CURRENT_EPOCH, $BASE_EPOCH' => sub {
	my $epoch = freeze_time('2025-01-01T00:00:00Z');
	ok $Test::Mockingbird::TimeTravel::ACTIVE,        '$ACTIVE set to 1';
	is $Test::Mockingbird::TimeTravel::CURRENT_EPOCH, $epoch, '$CURRENT_EPOCH set';
	is $Test::Mockingbird::TimeTravel::BASE_EPOCH,    $epoch, '$BASE_EPOCH set';
	Test::Mockingbird::TimeTravel::restore_all();
};

subtest 'freeze_time(): returns the frozen epoch integer' => sub {
	my $rv = freeze_time('2025-01-01T00:00:00Z');
	ok $rv =~ /^\d+$/, 'return value is an integer epoch';
	Test::Mockingbird::TimeTravel::restore_all();
};

subtest 'freeze_time(): accepts raw epoch integer' => sub {
	my $epoch = freeze_time(1234567890);
	is now(), 1234567890, 'raw epoch accepted';
	Test::Mockingbird::TimeTravel::restore_all();
};

subtest 'freeze_time(): two calls: second overrides first' => sub {
	my $t1 = freeze_time('2025-01-01T00:00:00Z');
	my $t2 = freeze_time('2026-01-01T00:00:00Z');
	ok $t2 > $t1,   'second freeze is later';
	is now(), $t2,  'now() returns second freeze';
	Test::Mockingbird::TimeTravel::restore_all();
};

subtest 'travel_to(): moves clock without unfreezing' => sub {
	# POD: "Move the frozen clock to a new timestamp without unfreezing."
	my $t0 = freeze_time('2025-01-01T00:00:00Z');
	my $t1 = travel_to('2025-06-01T00:00:00Z');
	ok $t1 > $t0,   'travel returned later epoch';
	is now(), $t1,  'now() updated';
	ok $Test::Mockingbird::TimeTravel::ACTIVE, 'still frozen (ACTIVE=1)';
	Test::Mockingbird::TimeTravel::restore_all();
};

subtest 'travel_to(): BASE_EPOCH unchanged after travel' => sub {
	# POD: "$BASE_EPOCH unchanged"
	my $base = freeze_time('2025-01-01T00:00:00Z');
	travel_to('2025-06-01T00:00:00Z');
	is $Test::Mockingbird::TimeTravel::BASE_EPOCH, $base,
		'$BASE_EPOCH unchanged after travel_to';
	Test::Mockingbird::TimeTravel::restore_all();
};

subtest 'travel_to(): croaks when TimeTravel is inactive' => sub {
	Test::Mockingbird::TimeTravel::restore_all();
	throws_ok { travel_to('2025-01-01T00:00:00Z') }
		qr/\Q$ERR_TT_TRAV\E/, 'travel_to() croaks when inactive';
};

subtest 'advance_time(): adds raw seconds' => sub {
	my $t0 = freeze_time('2025-01-01T00:00:00Z');
	my $t1 = advance_time(60);
	is $t1, $t0 + 60, 'return value is t0 + 60';
	is now(), $t0 + 60, 'now() reflects advance';
	Test::Mockingbird::TimeTravel::restore_all();
};

subtest 'advance_time(): adds duration in named units' => sub {
	my $t0 = freeze_time('2025-01-01T00:00:00Z');
	advance_time(2, 'minutes');
	is now(), $t0 + 120, '2 minutes = 120 seconds';
	advance_time(1, 'hour');
	is now(), $t0 + 120 + 3600, '1 hour = 3600 seconds';
	Test::Mockingbird::TimeTravel::restore_all();
};

subtest 'advance_time(): croaks when TimeTravel is inactive' => sub {
	Test::Mockingbird::TimeTravel::restore_all();
	throws_ok { advance_time(10) }
		qr/\Q$ERR_TT_ADV\E/, 'advance_time() croaks when inactive';
};

subtest 'rewind_time(): subtracts raw seconds' => sub {
	my $t0 = freeze_time('2025-01-01T00:00:00Z');
	my $t1 = rewind_time(30);
	is $t1, $t0 - 30, 'return value is t0 - 30';
	is now(), $t0 - 30, 'now() reflects rewind';
	Test::Mockingbird::TimeTravel::restore_all();
};

subtest 'rewind_time(): subtracts duration in named units' => sub {
	my $t0 = freeze_time('2025-01-01T00:00:00Z');
	rewind_time(1, 'day');
	is now(), $t0 - 86400, '1 day = 86400 seconds rewound';
	Test::Mockingbird::TimeTravel::restore_all();
};

subtest 'rewind_time(): croaks when TimeTravel is inactive' => sub {
	Test::Mockingbird::TimeTravel::restore_all();
	throws_ok { rewind_time(10) }
		qr/\Q$ERR_TT_REW\E/, 'rewind_time() croaks when inactive';
};

subtest 'TimeTravel::restore_all(): clears all state' => sub {
	freeze_time('2025-01-01T00:00:00Z');
	Test::Mockingbird::TimeTravel::restore_all();
	ok !$Test::Mockingbird::TimeTravel::ACTIVE,        '$ACTIVE cleared';
	ok !defined $Test::Mockingbird::TimeTravel::CURRENT_EPOCH, '$CURRENT_EPOCH undef';
	ok !defined $Test::Mockingbird::TimeTravel::BASE_EPOCH,    '$BASE_EPOCH undef';
	cmp_ok abs(now() - CORE::time()), '<', 3, 'now() returns real time';
};

subtest 'TimeTravel::restore_all(): idempotent' => sub {
	freeze_time('2025-01-01T00:00:00Z');
	Test::Mockingbird::TimeTravel::restore_all();
	lives_ok { Test::Mockingbird::TimeTravel::restore_all() }
		'second restore_all does not die';
};

subtest 'with_frozen_time(): block sees overridden time, outer restored' => sub {
	# POD: "Temporarily override time inside a code block, restoring previous
	# state afterward even if the block throws. Fully nestable."
	my $outer = freeze_time('2025-01-01T00:00:00Z');
	my $inner;
	with_frozen_time '2025-06-01T00:00:00Z' => sub {
		$inner = now();
	};
	ok $inner > $outer, 'block saw later time';
	is now(), $outer,   'outer time restored after block';
	Test::Mockingbird::TimeTravel::restore_all();
};

subtest 'with_frozen_time(): exception from block is re-thrown' => sub {
	# POD: "exceptions rethrown"
	my $outer = freeze_time('2025-01-01T00:00:00Z');
	throws_ok {
		with_frozen_time '2025-06-01T00:00:00Z' => sub { die "block error\n" };
	} qr/block error/, 'exception propagates';
	is now(), $outer, 'outer time intact despite exception';
	Test::Mockingbird::TimeTravel::restore_all();
};

subtest 'with_frozen_time(): fully nestable' => sub {
	# POD: "Fully nestable."  Inner scope must not permanently alter outer.
	my $t_outer = freeze_time('2025-01-01T00:00:00Z');
	my ($t_inner, $t_after_inner);
	with_frozen_time '2025-06-01T00:00:00Z' => sub {
		$t_inner = now();
		with_frozen_time '2026-01-01T00:00:00Z' => sub {
			# Innermost: just exercises the nesting; no assertion needed here
		};
		$t_after_inner = now();
	};
	ok $t_inner > $t_outer,          'inner scope saw later time';
	is $t_after_inner, $t_inner,     'inner-inner restored to inner on exit';
	is now(), $t_outer,              'outer time intact after all nesting';
	Test::Mockingbird::TimeTravel::restore_all();
};

subtest 'with_frozen_time(): croaks when coderef is missing' => sub {
	throws_ok { with_frozen_time('2025-01-01T00:00:00Z', 'not_code') }
		qr/\Q$ERR_TT_CODE\E/, 'non-CODE second arg croaks';
};

subtest 'with_frozen_time(): croaks when timestamp is undef' => sub {
	throws_ok { with_frozen_time(undef, sub {}) }
		qr/\Q$ERR_TT_TS\E/, 'undef timestamp croaks';
};

# ============================================================================
#  Cleanup: ensure no mock state leaks between test files
# ============================================================================

Test::Mockingbird::restore_all();
Test::Mockingbird::TimeTravel::restore_all();

done_testing;
