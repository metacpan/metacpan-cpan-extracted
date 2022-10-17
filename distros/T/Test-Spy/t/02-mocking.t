use v5.10;
use strict;
use warnings;

use Test::More;
use Test::Spy;

subtest 'testing mocking a method to return undef (no argument)' => sub {
	my $spy = Test::Spy->new;
	$spy->add_method('meth');

	is $spy->object->meth, undef, 'method return value ok';
};

subtest 'testing mocking a method to return a scalar (method 1)' => sub {
	my $spy = Test::Spy->new;
	$spy->add_method('meth', 'scalar');

	is $spy->object->meth, 'scalar', 'method return value ok';
};

subtest 'testing mocking a method to return a scalar (method 2)' => sub {
	my $spy = Test::Spy->new;
	$spy->add_method('meth')->should_return('scalar');

	is $spy->object->meth, 'scalar', 'method return value ok';
};

subtest 'testing mocking a method to return a list (method 1)' => sub {
	my $spy = Test::Spy->new;
	$spy->add_method('meth', 2, 3);

	is_deeply [$spy->object->meth], [2, 3], 'method return value ok';
};

subtest 'testing mocking a method to return a list (method 2)' => sub {
	my $spy = Test::Spy->new;
	$spy->add_method('meth')->should_return(2, 3);

	is_deeply [$spy->object->meth], [2, 3], 'method return value ok';
};

subtest 'testing mocking a method to call custom code' => sub {
	my $called;
	my @arguments;
	my $spy = Test::Spy->new;
	$spy->add_method('meth')->should_call(sub { @arguments = @_; $called = 1 });

	$spy->object->meth(2, 3);
	ok $called, 'custom code was called ok';
	is_deeply [@arguments], [$spy->object, 2, 3], 'custom code arguments ok';
};

subtest 'testing mocking a method to throw an exception' => sub {
	my $exception = \'a custom error';
	my $spy = Test::Spy->new;
	$spy->add_method('meth')->should_throw($exception);

	my $result = eval {
		$spy->object->meth;
		1;
	};

	ok !$result, 'exception thrown ok';
	is $@, $exception, 'exception ok';
};

done_testing;

