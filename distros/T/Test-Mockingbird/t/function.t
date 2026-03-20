use strict;
use warnings;
use Test::Most;
use Test::Warnings;
use Test::Deep;
use Test::Strict;
use Test::Vars;
use lib 'lib';

use Test::Mockingbird;

use_ok('Test::Mockingbird::DeepMock');

# ----------------------------------------------------------------------
# FUNCTION LEVEL TESTS
# ----------------------------------------------------------------------

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

# ----------------------------------------------------------------------
subtest '_normalize_target does not validate method existence' => sub {
	lives_ok {
		Test::Mockingbird::DeepMock::_normalize_target('NoMethodHere');
	} 'normalize_target does not croak on missing method';
};

# ----------------------------------------------------------------------
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

	ok $handles{sa}{spy},  'spy handle stored';
	ok $handles{mb}{guard}, 'mock guard stored';

	is FM1A::b(), 99, 'mocked method returns expected value';

	Test::Mockingbird::restore_all();
};

# ----------------------------------------------------------------------
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

# ----------------------------------------------------------------------
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

# ----------------------------------------------------------------------
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
					tag		 => 's',
					args_like   => [ [ qr/alpha/ ] ],
					args_deeply => [ undef, [ { a => 1 } ] ],
				},
			],
			\%handles,
		);
	} 'argument matchers pass';

	Test::Mockingbird::restore_all();
};

# ----------------------------------------------------------------------
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

# ----------------------------------------------------------------------
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


# ----------------------------------------------------------------------
done_testing();
