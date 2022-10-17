use v5.10;
use strict;
use warnings;

use Test::More;
use Test::Spy;

subtest 'testing context value' => sub {
	my $spy = Test::Spy->new;

	$spy->set_context('meth');
	is $spy->context, 'meth', 'context ok';
	ok $spy->has_context, 'has context ok';

	$spy->clear_context;
	ok !$spy->has_context, 'cleared context ok';
};

subtest 'testing context in constructor' => sub {
	my $spy = Test::Spy->new(context => 'meth');
	$spy->add_method('meth');

	$spy->object->meth(qw(a b c));

	is_deeply $spy->called_with, [qw(a b c)], 'context ok';
};

subtest 'testing context with a method' => sub {
	my $spy = Test::Spy->new;
	$spy->add_method('meth');
	$spy->set_context('meth');

	$spy->object->meth(qw(a b c));

	is_deeply $spy->called_with, [qw(a b c)], 'context ok';
};

subtest 'testing no context' => sub {
	my $spy = Test::Spy->new;

	my $result = eval {
		$spy->call_history;
		1;
	};

	ok !$result, 'call_history died ok';
	like $@, qr/no context was set/, 'call_history error message ok';
};

subtest 'testing clear context method' => sub {
	my $spy = Test::Spy->new;

	$spy->add_method('meth');
	$spy->set_context('meth');

	$spy->object->meth;

	ok $spy->was_called_once, 'call history 1 ok';

	$spy->clear;

	ok $spy->was_called(0), 'call history 2 ok';
};

subtest 'testing clearing with clear_all' => sub {
	my $spy = Test::Spy->new;
	my $method = $spy->add_method('test');
	my $method2 = $spy->add_method('test2');

	$spy->object->test;
	$spy->object->test;
	$spy->object->test2;
	$spy->set_context('test');
	$spy->clear_all;

	ok $method->wasnt_called, 'method 1 ok';
	ok $method2->wasnt_called, 'method 2 ok';
	ok !$spy->has_context, 'context ok';
};


done_testing;

