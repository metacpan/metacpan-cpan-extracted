use v5.10;
use strict;
use warnings;

use Test::More;

BEGIN {
	use_ok('Test::Spy');
}

subtest 'testing empty object creation with a spy' => sub {
	my $spy = Test::Spy->new;
	my $object = $spy->object;

	ok ref $object, 'object from spy created ok';
};

subtest 'testing mocking a method' => sub {
	my $spy = Test::Spy->new;
	my $method = $spy->add_method('test');

	is $method, $spy->method('test'), 'method getting ok';
	isa_ok $method, 'Test::Spy::Method';

	my $object = $spy->object;
	can_ok $object, 'test';
};

done_testing;

