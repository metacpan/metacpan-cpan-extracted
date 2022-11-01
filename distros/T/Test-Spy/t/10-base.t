use v5.10;
use strict;
use warnings;

use Test::More;
use Test::Spy;

{
	package MockTest;

	use Moo;

	sub mock_deep {
		return 'deep';
	}

	sub mock_shallow {
		return shift->mock_deep . ' shallow';
	}
}

subtest 'testing observers' => sub {
	my $spy = Test::Spy->new(base => MockTest->new);

	$spy->add_observer('mock_deep');

	my $obj = $spy->object;

	is $obj->mock_deep, 'deep';
	is $obj->mock_shallow, 'deep shallow';

	$spy->set_context('mock_deep');
	ok $spy->was_called(2), 'mock called ok';
};

subtest 'testing methods' => sub {
	my $spy = Test::Spy->new(base => MockTest->new);

	$spy->add_method('mock_deep', 'mocked');

	my $obj = $spy->object;

	is $obj->mock_deep, 'mocked';
	is $obj->mock_shallow, 'mocked shallow';

	$spy->set_context('mock_deep');
	ok $spy->was_called(2), 'mock called ok';
};

subtest 'testing Test::Spy mocking Test::Spy' => sub {
	my $spy = Test::Spy->new(base => 'Test::Spy');

	$spy->add_method('add_method', 'mocked');

	my $obj = $spy->object;

	isa_ok $obj, 'Test::Spy';
	ok !$obj->isa('Moo'), 'invalid isa ok';

	ok $obj->DOES('Test::Spy::Interface'), 'DOES ok';
	ok !$obj->DOES('Test::Spy::Method'), 'invalid DOES ok';

	can_ok $obj, 'add_method', 'method';
	ok !$obj->can('doesnt_exist'), 'non existent method can ok';

	is $obj->add_method('test'), 'mocked', 'object method mocked ok';

	my $result = eval {
		$obj->method('test');
		1;
	};

	ok !$result, 'get method ok';
	like $@, qr/was not mocked/, 'exception ok';
};

done_testing;

