use v5.10;
use strict;
use warnings;

use Test::More;
use Test::Spy;

subtest 'testing basic call data' => sub {
	my $spy = Test::Spy->new;
	my $method = $spy->add_method('meth');

	$spy->object->meth(qw(a b c));

	is $method->called_times, 1, 'called_times ok';
	is_deeply $method->call_history, [[qw(a b c)]], 'call history ok';

	$spy->object->meth(qw(d e f));

	is $method->called_times, 2, 'called_times 2 ok';
	is_deeply $method->call_history, [[qw(a b c)], [qw(d e f)]], 'call history 2 ok';
};

subtest 'testing was_called' => sub {
	my $spy = Test::Spy->new;
	my $method = $spy->add_method('meth');

	ok $method->wasnt_called, 'no calls - was_called ok';
	ok !$method->was_called, 'no calls - was_called 2 ok';
	ok !$method->was_called_once, 'no calls - was_called_once ok';
	ok !$method->was_called(2), 'no calls - was_called 3 ok';
	ok $method->was_called(0), 'no calls - was_called 4 ok';

	$spy->object->meth;

	ok $method->was_called, 'one call - was_called ok';
	ok $method->was_called(1), 'one call - was_called 2 ok';
	ok $method->was_called_once, 'one call - was_called_once ok';
	ok !$method->was_called(2), 'one call - was_called 3 ok';
	ok !$method->was_called(0), 'one call - was_called 4 ok';

	$spy->object->meth;

	ok $method->was_called, 'two calls - was_called ok';
	ok !$method->was_called(1), 'two calls - was_called 2 ok';
	ok !$method->was_called_once, 'two calls - was_called_once ok';
	ok $method->was_called(2), 'two calls - was_called 3 ok';
	ok !$method->was_called(0), 'two calls - was_called 4 ok';
};

subtest 'testing call history iterators' => sub {
	my $spy = Test::Spy->new;
	my $method = $spy->add_method('meth');

	$spy->object->meth(1, $spy);
	$spy->object->meth(2, $spy);
	$spy->object->meth(3, $spy);
	$spy->object->meth(4, $spy);

	is_deeply $method->first_called_with, [1, $spy], 'call 1 ok';
	is_deeply $method->next_called_with, [2, $spy], 'call 2 ok';
	is_deeply $method->next_called_with, [3, $spy], 'call 3 ok';
	is_deeply $method->called_with, [3, $spy], 'call 3 ok (repeated)';
	is_deeply $method->next_called_with, [4, $spy], 'call 4 ok';

	$spy->object->meth(5, $spy);

	is_deeply $method->next_called_with, [5, $spy], 'call 5 ok';
	is_deeply $method->last_called_with, [5, $spy], 'call 5 ok (last)';
	is $method->next_called_with, undef, 'out of calls ok';

	$method->clear;

	is $method->next_called_with, undef, 'out of calls ok (cleared)';
};

subtest 'testing call history iterators (edge cases)' => sub {
	my $spy = Test::Spy->new;
	my $method = $spy->add_method('meth');

	$spy->object->meth(1);
	$spy->object->meth(2);
	$spy->object->meth(3);

	# first / last
	is_deeply $method->called_with, [1], 'call 1 ok';
	is_deeply $method->last_called_with, [3], 'call 2 ok';

	$spy->object->meth(4);

	# continuing after last (new call)
	is_deeply $method->next_called_with, [4], 'call 3 ok';

	$method->clear;
	$spy->object->meth(1);
	$spy->object->meth(2);
	$spy->object->meth(3);
	$spy->object->meth(4);
	$spy->object->meth(5);

	# continuing after clear, enough calls for old iterator, but we start at 0
	# (plus start with next_called_with at index 0)
	is_deeply $method->next_called_with, [1], 'call 4 ok';
	is_deeply $method->next_called_with, [2], 'call 5 ok';
};

done_testing;

