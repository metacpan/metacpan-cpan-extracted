use strict;
use warnings;
use Test::Most;
use Test::Warnings;
use Test::Deep;
use lib 'lib';

use Test::Mockingbird;
use Test::Mockingbird::TimeTravel;
use_ok('Test::Mockingbird::DeepMock');

# ----------------------------------------------------------------------
# FUNCTION LEVEL TESTS
# ----------------------------------------------------------------------

subtest '_normalize_target basic parsing' => sub {
	my ($pkg, $meth);

	($pkg, $meth) = Test::Mockingbird::DeepMock::_normalize_target('Foo::bar');
	is $pkg,  'Foo', 'parsed package correctly';
	is $meth, 'bar', 'parsed method correctly';

	($pkg, $meth) = Test::Mockingbird::DeepMock::_normalize_target('Foo', 'bar');
	is $pkg,  'Foo', 'separate package ok';
	is $meth, 'bar', 'separate method ok';
};

subtest '_normalize_target does not validate method existence' => sub {
	lives_ok {
		Test::Mockingbird::DeepMock::_normalize_target('NoMethodHere');
	} 'normalize_target does not croak on missing method';
};

subtest '_install_mocks installs spies and mocks' => sub {
	{
		package FM1A;
		sub a { 1 }
		sub b { 2 }
	}

	my @guards;
	my %handles;

	lives_ok {
		@guards = Test::Mockingbird::DeepMock::_install_mocks(
			[
				{ target => 'FM1A::a', type => 'spy',  tag => 'sa' },
				{ target => 'FM1A::b', type => 'mock', tag => 'mb', with => sub { 99 } },
			],
			\%handles,
		);
	} 'install_mocks lives';

	ok $handles{sa}{spy},   'spy handle stored';
	ok $handles{mb}{guard}, 'mock guard stored';

	is FM1A::b(), 99, 'mocked method returns expected value';

	Test::Mockingbird::restore_all();
};

subtest '_install_mocks croaks on missing with coderef' => sub {
	dies_ok {
		Test::Mockingbird::DeepMock::_install_mocks(
			[
				{ target => 'X1::y', type => 'mock', tag => 'bad' },
			],
			{},
		);
	} 'croaks on missing with coderef';
};

subtest '_run_expectations basic call count' => sub {
	{
		package FM2A;
		sub foo { $_[1] }
	}

	my %handles;
	my $spy = Test::Mockingbird::spy('FM2A', 'foo');
	$handles{s}{spy} = $spy;

	FM2A::foo('x');
	FM2A::foo('y');

	lives_ok {
		Test::Mockingbird::DeepMock::_run_expectations(
			[
				{ tag => 's', calls => 2 },
			],
			\%handles,
		);
	} 'call count expectation passes';

	Test::Mockingbird::restore_all();
};

subtest '_run_expectations args_like and args_deeply' => sub {
	{
		package FM3A;
		sub foo { $_[1] }
	}

	my %handles;
	my $spy = Test::Mockingbird::spy('FM3A', 'foo');
	$handles{s}{spy} = $spy;

	FM3A::foo('alpha');
	FM3A::foo({ a => 1 });

	lives_ok {
		Test::Mockingbird::DeepMock::_run_expectations(
			[
				{
					tag        => 's',
					args_like  => [ [ qr/alpha/ ] ],
					args_deeply => [ undef, [ { a => 1 } ] ],
				},
			],
			\%handles,
		);
	} 'argument matchers pass';

	Test::Mockingbird::restore_all();
};

subtest '_run_expectations never' => sub {
	{
		package FM4A;
		sub foo { $_[1] }
	}

	my %handles;
	my $spy = Test::Mockingbird::spy('FM4A', 'foo');
	$handles{s}{spy} = $spy;

	lives_ok {
		Test::Mockingbird::DeepMock::_run_expectations(
			[
				{ tag => 's', never => 1 },
			],
			\%handles,
		);
	} 'never expectation passes when no calls made';

	Test::Mockingbird::restore_all();
};

subtest 'deep_mock basic function-level integration' => sub {
	{
		package FM5A;
		sub foo { $_[1] }
	}

	lives_ok {
		Test::Mockingbird::DeepMock::deep_mock(
			{
				mocks => [
					{ target => 'FM5A::foo', type => 'spy', tag => 's' },
				], expectations => [
					{ tag => 's', calls => 1 },
				],
			},
			sub {
				FM5A::foo('hello');
			},
		);
	} 'deep_mock basic function-level integration passes';
};

subtest 'mock_return basic behaviour' => sub {
	{
		package Edge::Target;
		sub x { return 'orig' }
	}

	mock_return 'Edge::Target::x' => 123;
	is Edge::Target::x(), 123, 'mock_return overrides method';
	restore_all();
};

subtest 'mock_exception basic behaviour' => sub {
	{
		package Edge::Target;
		sub y { return 'orig' }
	}

	mock_exception 'Edge::Target::y' => 'boom';
	dies_ok { Edge::Target::y() } 'mock_exception throws';
	like $@, qr/boom/, 'exception message matches';
	restore_all();
};

subtest 'mock_sequence basic behaviour' => sub {
	{
		package Edge::Target;
		sub z { return 'orig' }
	}

	mock_sequence 'Edge::Target::z' => (10, 20, 30);
	is Edge::Target::z(), 10, 'first value';
	is Edge::Target::z(), 20, 'second value';
	is Edge::Target::z(), 30, 'third value';
	is Edge::Target::z(), 30, 'sequence repeats last value';
	restore_all();
};

subtest 'mock_once basic behaviour' => sub {
	{
		package Edge::Target;
		sub a { return 'orig' }
	}

	mock_once 'Edge::Target::a' => sub { 'once' };
	is Edge::Target::a(), 'once', 'first call uses mock_once';
	is Edge::Target::a(), 'orig', 'second call restored original';
	restore_all();
};

subtest 'restore basic behaviour' => sub {
	{
		package Edge::Restore;
		sub a { return 'orig' }
	}

	mock_return 'Edge::Restore::a' => 'mocked';
	is Edge::Restore::a(), 'mocked', 'mock applied';
	restore 'Edge::Restore::a';
	is Edge::Restore::a(), 'orig', 'restore restored original';
	restore_all();
};

subtest 'diagnose_mocks basic structure' => sub {
	{
		package DM::F1;
		sub a { 1 }
	}

	mock_return 'DM::F1::a' => 42;
	my $diag = diagnose_mocks();
	ok exists $diag->{'DM::F1::a'}, 'entry exists';
	is $diag->{'DM::F1::a'}{depth}, 1, 'depth correct';
	is $diag->{'DM::F1::a'}{layers}[0]{type}, 'mock_return', 'type recorded';
	restore_all();
};

# We test internal helpers by reaching into the package (white-box)
{
	package TT;
	our $parse  = \&Test::Mockingbird::TimeTravel::_parse_datetime;
	our $ensure = \&Test::Mockingbird::TimeTravel::_ensure_active;
	our $install = \&Test::Mockingbird::TimeTravel::_install_time_mocks;
}

subtest '_parse_datetime parses valid formats' => sub {
	my $epoch = $TT::parse->('2025-01-01T00:00:00Z');
	ok $epoch =~ /^\d+$/, 'epoch returned';

	my $epoch2 = $TT::parse->('2025-01-01 12:34:56');
	ok $epoch2 > $epoch, 'later timestamp parsed';

	my $epoch3 = $TT::parse->('2025-01-01');
	ok $epoch3 == $TT::parse->('2025-01-01T00:00:00Z'),
		'date-only defaults to midnight UTC';
};

subtest '_parse_datetime rejects invalid formats' => sub {
	dies_ok { $TT::parse->('not-a-date') } 'invalid string dies';
	dies_ok { $TT::parse->('2025/01/01') } 'wrong separator dies';
	dies_ok { $TT::parse->(undef) }        'undef dies';
};

subtest '_ensure_active dies when no freeze_time called' => sub {
	restore_all();
	dies_ok { $TT::ensure->() } '_ensure_active dies when inactive';
};

subtest 'freeze_time sets epoch and installs mocks' => sub {
	restore_all();
	my $epoch = freeze_time('2025-01-01T00:00:00Z');
	ok $epoch =~ /^\d+$/, 'freeze_time returns epoch';
	is now(), $epoch, 'now() returns frozen time';
	my @lt = localtime();
	ok @lt == 9, 'localtime returns list';
	my @gt = gmtime();
	ok @gt == 9, 'gmtime returns list';
	restore_all();
};

subtest 'freeze_time accepts raw epoch' => sub {
	restore_all();
	my $epoch = freeze_time(1234567890);
	is now(), 1234567890, 'raw epoch accepted';
	restore_all();
};

subtest 'travel_to moves time forward' => sub {
	restore_all();
	freeze_time('2025-01-01T00:00:00Z');
	my $t1 = now();
	travel_to('2025-01-01T01:00:00Z');
	my $t2 = now();
	ok $t2 > $t1, 'travel_to updated epoch';
	restore_all();
};

subtest 'travel_to dies when inactive' => sub {
	restore_all();
	dies_ok { travel_to('2025-01-01T00:00:00Z') } 'travel_to dies when inactive';
};

subtest 'advance_time increments epoch' => sub {
	restore_all();
	freeze_time('2025-01-01T00:00:00Z');
	my $t1 = now();
	advance_time(60);
	is now(), $t1 + 60, 'advance_time +60 seconds';
	advance_time(2 => 'minutes');
	is now(), $t1 + 60 + 120, 'advance_time +2 minutes';
	restore_all();
};

subtest 'rewind_time decrements epoch' => sub {
	restore_all();
	freeze_time('2025-01-01T00:00:00Z');
	my $t1 = now();
	rewind_time(30);
	is now(), $t1 - 30, 'rewind_time -30 seconds';
	rewind_time(1 => 'hour');
	is now(), $t1 - 30 - 3600, 'rewind_time -1 hour';
	restore_all();
};

subtest 'advance_time dies when inactive' => sub {
	restore_all();
	dies_ok { advance_time(10) } 'advance_time dies when inactive';
};

subtest 'with_frozen_time runs code under frozen time' => sub {
	restore_all();
	my $outer = freeze_time('2025-01-01T00:00:00Z');
	my $inner;
	with_frozen_time '2025-01-02T00:00:00Z' => sub {
		$inner = now();
	};
	is $inner, $TT::parse->('2025-01-02T00:00:00Z'),
		'inner block sees overridden time';
	is now(), $outer, 'outer time restored after block';
	restore_all();
};

subtest 'with_frozen_time dies on invalid args' => sub {
	restore_all();
	dies_ok { with_frozen_time undef => sub {} } 'undef datetime dies';
	dies_ok { with_frozen_time '2025-01-01' => 'not a coderef' }
		'non-coderef dies';
};

subtest 'restore_all restores real time' => sub {
	restore_all();
	freeze_time('2025-01-01T00:00:00Z');
	ok now() != CORE::time(), 'mocked time differs from real time';
	restore_all();
	cmp_ok abs(now() - CORE::time()), '<', 3, 'restore_all restored real time';
};

subtest '_get_prototype' => sub {
	{
		package Foo::Bar;
		sub baz ($$) { }
	}

	is(Test::Mockingbird::_get_prototype('Foo::Bar::baz'), '$$',
		'prototype extracted correctly');
	ok(!defined Test::Mockingbird::_get_prototype('Foo::Bar::nope'),
		'undefined for missing sub');
	throws_ok { Test::Mockingbird::_get_prototype('NotAName') }
		qr/Invalid fully-qualified name/, 'invalid name throws';
};

# ----------------------------------------------------------------------
# PROTOTYPE PRESERVATION TESTS
# Verify that mock() copies the original prototype onto the replacement
# so that call-site prototype checking does not emit mismatch warnings.
# ----------------------------------------------------------------------

subtest 'mock() emits no warning when replacing a () prototype function' => sub {
	# () is the canonical case: I18N::LangTags::Detect::detect uses it,
	# and it caused "Prototype mismatch: sub ... ()" warnings before the fix.
	{
		package Proto::Func::NoArgs;
		sub detect () { 'real' }
	}

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, $_[0] };

	mock 'Proto::Func::NoArgs::detect' => sub { 'mocked' };

	# Direct literal calls to a () prototype function are constant-folded
	# at compile time; use ->can() for a runtime lookup through the mock.
	my $caller = Proto::Func::NoArgs->can('detect');
	my $val = $caller->();
	unmock 'Proto::Func::NoArgs::detect';

	is $val, 'mocked', 'mocked return value is correct (via ->can())';
	ok !@warnings,     'no prototype-mismatch warning emitted during mock/unmock';
};

subtest 'mock() emits no warning when replacing a ($$) prototype function' => sub {
	{
		package Proto::Func::TwoArgs;
		sub add ($$) { $_[0] + $_[1] }
	}

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, $_[0] };

	mock 'Proto::Func::TwoArgs::add' => sub { 99 };
	Proto::Func::TwoArgs::add(1, 2);
	restore_all();

	ok !@warnings, 'no warning for $$ prototype function';
};

subtest 'mock() on no-prototype function emits no spurious warning' => sub {
	{
		package Proto::Func::Plain;
		sub greet { 'hello' }
	}

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, $_[0] };

	mock   'Proto::Func::Plain::greet' => sub { 'hi' };
	unmock 'Proto::Func::Plain::greet';

	ok !@warnings, 'no warning when original had no prototype';
};

done_testing();
