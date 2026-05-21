#!/usr/bin/env perl

use strict;
use warnings;

use lib 'lib';

use Test::Most;
use Test::Mockingbird;
use_ok('Test::Mockingbird::DeepMock');

# ----------------------------------------------------------------------
# UNIT LEVEL TESTS
# ----------------------------------------------------------------------

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
		sub foo { "orig" }
		sub bar { $X }
	}

	my %handles;
	my @installed = Test::Mockingbird::DeepMock::_install_mocks(
		[
			{
				target => 'UT1::foo',
				type   => 'mock',
				with   => sub { "mocked" },
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
	ok $handles{f}{guard}, 'mock tag stored';
	ok $handles{b}{spy},   'spy tag stored';
	cmp_ok scalar(@installed), '==', 2, 'two entries returned from _install_mocks';

	Test::Mockingbird::restore_all();
};

subtest '_install_mocks error handling' => sub {
	dies_ok {
		Test::Mockingbird::DeepMock::_install_mocks(
			[ { type => 'mock', with => sub {} } ],
			{}
		);
	} 'missing target dies';

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
	dies_ok {
		Test::Mockingbird::DeepMock::_run_expectations(
			[ { calls => 1 } ],
			{}
		);
	} 'missing tag dies';
};

subtest '_run_expectations missing spy dies' => sub {
	dies_ok {
		Test::Mockingbird::DeepMock::_run_expectations(
			[ { tag => 'nope', calls => 1 } ],
			{}
		);
	} 'missing spy handle dies';
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

	Test::Mockingbird::DeepMock::_run_expectations(
		[ { tag => 's', never => 1 } ],
		\%handles,
	);

	Test::Mockingbird::restore_all();
};

subtest 'mock_return stacks with mock' => sub {
	{
		package Edge::Target;
		sub a { return 'orig' }
	}

	mock_return 'Edge::Target::a' => 'first';
	mock 'Edge::Target::a' => sub { 'second' };
	is Edge::Target::a(), 'second', 'top mock wins';
	restore_all();
};

subtest 'mock_sequence with restore_all' => sub {
	{
		package Edge::Target;
		sub b { return 'orig' }
	}

	mock_sequence 'Edge::Target::b' => (1, 2);
	is Edge::Target::b(), 1, 'first';
	is Edge::Target::b(), 2, 'second';
	restore_all();
	is Edge::Target::b(), 'orig', 'restore_all restores original';
};

subtest 'mock_once stacks correctly' => sub {
	{
		package Edge::Target;
		sub c { return 'orig' }
	}

	mock_return 'Edge::Target::c' => 'first';
	mock_once   'Edge::Target::c' => sub { 'once' };
	is Edge::Target::c(), 'once',  'mock_once fires first';
	is Edge::Target::c(), 'first', 'then previous mock restored';
	restore_all();
};

subtest 'restore unwinds stacked mocks' => sub {
	{
		package Edge::Restore;
		sub b { return 'orig' }
	}

	mock_return 'Edge::Restore::b' => 'layer1';
	mock_return 'Edge::Restore::b' => 'layer2';
	is Edge::Restore::b(), 'layer2', 'top layer active';
	restore 'Edge::Restore::b';
	is Edge::Restore::b(), 'orig', 'all layers removed';
	restore_all();
};

subtest 'diagnose_mocks tracks stacked layers' => sub {
	{
		package DM::U1;
		sub b { 1 }
	}

	mock_return    'DM::U1::b' => 10;
	mock_exception 'DM::U1::b' => 'boom';

	my $diag = diagnose_mocks();
	is $diag->{'DM::U1::b'}{depth}, 2, 'two layers recorded';

	my @types = map $_->{type}, @{ $diag->{'DM::U1::b'}{layers} };
	is_deeply \@types, [ 'mock_return', 'mock_exception' ], 'types in order';

	restore_all();
};

# ----------------------------------------------------------------------
# PROTOTYPE PRESERVATION -- WHITE-BOX UNIT TESTS
#
# These tests reach directly into the symbol table to verify that
# Scalar::Util::set_prototype has actually been applied to the
# replacement coderef by mock().  They are white-box by design:
# the public API gives no other way to observe the prototype value.
# ----------------------------------------------------------------------

subtest 'mock() stamps () prototype onto replacement coderef' => sub {
	# () is the canonical problem case: I18N::LangTags::Detect::detect
	# uses it and previously caused "Prototype mismatch" warnings.
	{
		package Proto::Unit::NoArgs;
		sub detect () { 'real' }
	}

	mock 'Proto::Unit::NoArgs::detect' => sub { 'mocked' };

	# prototype() on the currently installed glob must return ''
	# (the stringified form of a () no-args prototype)
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
	# set_prototype must only fire when defined $proto -- an undef prototype
	# means the original had none, and the replacement must remain prototype-free.
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
	# Reinstating the original coderef via glob assignment brings its
	# prototype back automatically -- no extra set_prototype required.
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
	# Each successive mock() call must stamp the prototype independently;
	# the prototype seen at any depth must be the original one.
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

done_testing;
