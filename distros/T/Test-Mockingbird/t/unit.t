#!/usr/bin/env perl

use strict;
use warnings;

use lib 'lib';

use Test::Most;
use Test::Mockingbird;
use_ok('Test::Mockingbird::DeepMock');

# We need direct access to internal functions
# so we call them via fully-qualified names.
# This is normal for unit tests of private helpers.

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

# ----------------------------------------------------------------------
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
				tag	=> 'f',
			},
			{
				target => 'UT1::bar',
				type   => 'spy',
				tag	=> 'b',
			},
		],
		\%handles,
	);

	is UT1::foo(), 'mocked', 'mock installed';
	is UT1::bar(), 10,	   'spy installed (original behavior preserved)';

	ok $handles{f}{guard}, 'mock tag stored';
	ok $handles{b}{spy},   'spy tag stored';

	cmp_ok scalar(@installed), '==', 2, 'two entries returned from _install_mocks';

	# cleanup
	Test::Mockingbird::restore_all();
};

# ----------------------------------------------------------------------
subtest '_install_mocks error handling' => sub {

	dies_ok {
		Test::Mockingbird::DeepMock::_install_mocks(
			[ { type => 'mock', with => sub {} } ],   # missing target
			{}
		);
	} 'missing target dies';

	dies_ok {
		Test::Mockingbird::DeepMock::_install_mocks(
			[ { target => 'A::b', type => 'wut' } ],  # unknown type
			{}
		);
	} 'unknown type dies';
};

# ----------------------------------------------------------------------
subtest '_run_expectations call count' => sub {

	{
		package UT2;
		sub foo { ($_[1] // 0) * 2 }
	}

	my %handles;

	# Install a single spy and store it
	my $spy = Test::Mockingbird::spy('UT2', 'foo');
	$handles{spy1}{spy} = $spy;

	# Call the method twice
	UT2::foo(10);
	UT2::foo(20);

	Test::Mockingbird::DeepMock::_run_expectations(
		[
			{
				tag   => 'spy1',
				calls => 2,
			}
		],
		\%handles,
	);

	Test::Mockingbird::restore_all();
};


# ----------------------------------------------------------------------
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
				tag	  => 's',
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

# ----------------------------------------------------------------------
subtest '_run_expectations missing tag dies' => sub {

	dies_ok {
		Test::Mockingbird::DeepMock::_run_expectations(
			[ { calls => 1 } ],   # missing tag
			{}
		);
	} 'missing tag dies';
};

# ----------------------------------------------------------------------
subtest '_run_expectations missing spy dies' => sub {

	dies_ok {
		Test::Mockingbird::DeepMock::_run_expectations(
			[ { tag => 'nope', calls => 1 } ],
			{}
		);
	} 'missing spy handle dies';
};

# ----------------------------------------------------------------------
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
		[
			{
				tag	 => 's',
				args_eq => [
					[ 'x' ],
					[ 'y' ],
				],
			}
		],
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
				tag		 => 's',
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

# ----------------------------------------------------------------------
subtest '_run_expectations never' => sub {

	{
		package UT_NEVER;
		sub foo { $_[1] }
	}

	my %handles;

	# Install a spy but do NOT call the method
	my $spy = Test::Mockingbird::spy('UT_NEVER', 'foo');
	$handles{s}{spy} = $spy;

	Test::Mockingbird::DeepMock::_run_expectations(
		[
			{
				tag   => 's',
				never => 1,
			}
		],
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

done_testing;
