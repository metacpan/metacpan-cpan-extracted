use strict;
use warnings;

use Test::Most;
use Test::Needs 'Future';
use Test::Mockingbird;
use Test::Mockingbird::Async qw(
	mock_future_return
	mock_future_fail
	mock_future_sequence
	mock_future_once
	async_spy
);

# -----------------------------------------------------------------
# Setup: a package whose methods we will mock / spy on
# -----------------------------------------------------------------
{
	package My::DB;
	sub fetch  { 'real_fetch'  }
	sub save   { 'real_save'   }
	sub ping   { 'real_ping'   }
	sub delete { 'real_delete' }
}

# =================================================================
# mock_future_return
# =================================================================

subtest 'mock_future_return — scalar value' => sub {
	mock_future_return 'My::DB::fetch' => 42;

	my $f = My::DB::fetch();
	isa_ok $f, 'Future', 'returns a Future';
	ok $f->is_done,    'Future is resolved';
	is $f->get, 42,    'resolves to mocked value';

	restore_all();
	is My::DB::fetch(), 'real_fetch', 'original restored';
};

subtest 'mock_future_return — multi-value list' => sub {
	mock_future_return 'My::DB::fetch' => (1, 2, 3);

	my @vals = My::DB::fetch()->get;
	is_deeply \@vals, [1, 2, 3], 'resolves to mocked list';

	restore_all();
};

subtest 'mock_future_return — undef value' => sub {
	mock_future_return 'My::DB::fetch' => undef;

	my $f = My::DB::fetch();
	ok $f->is_done, 'Future is resolved even for undef';
	ok !defined $f->get, 'resolves to undef';

	restore_all();
};

subtest 'mock_future_return — recorded in diagnose_mocks' => sub {
	mock_future_return 'My::DB::fetch' => 1;

	my $diag = diagnose_mocks();
	is $diag->{'My::DB::fetch'}{layers}[0]{type},
		'mock_future_return', 'type is mock_future_return';

	restore_all();
};

# =================================================================
# mock_future_fail
# =================================================================

subtest 'mock_future_fail — simple message' => sub {
	mock_future_fail 'My::DB::fetch' => 'not found';

	my $f = My::DB::fetch();
	isa_ok $f, 'Future';
	ok $f->is_failed, 'Future is failed';

	my ($msg) = $f->failure;
	is $msg, 'not found', 'failure message matches';

	restore_all();
	is My::DB::fetch(), 'real_fetch', 'original restored';
};

subtest 'mock_future_fail — with category and detail' => sub {
	mock_future_fail 'My::DB::fetch' => ('db error', 'db', { code => 500 });

	my ($msg, $cat, $detail) = My::DB::fetch()->failure;
	is $msg,            'db error', 'message';
	is $cat,            'db',       'category';
	is $detail->{code}, 500,        'detail hashref';

	restore_all();
};

subtest 'mock_future_fail — does not throw at call site' => sub {
	mock_future_fail 'My::DB::fetch' => 'boom';

	my $f;
	lives_ok { $f = My::DB::fetch() } 'call site does not throw';
	ok $f->is_failed, 'returned Future carries the failure';

	restore_all();
};

subtest 'mock_future_fail — recorded in diagnose_mocks' => sub {
	mock_future_fail 'My::DB::fetch' => 'x';

	my $diag = diagnose_mocks();
	is $diag->{'My::DB::fetch'}{layers}[0]{type},
		'mock_future_fail', 'type is mock_future_fail';

	restore_all();
};

# =================================================================
# mock_future_sequence
# =================================================================

subtest 'mock_future_sequence — plain values in order, last repeats' => sub {
	mock_future_sequence 'My::DB::fetch' => (10, 20, 30);

	is My::DB::fetch()->get, 10, 'call 1';
	is My::DB::fetch()->get, 20, 'call 2';
	is My::DB::fetch()->get, 30, 'call 3';
	is My::DB::fetch()->get, 30, 'call 4 repeats last';

	restore_all();
};

subtest 'mock_future_sequence — pre-built Futures passed through' => sub {
	mock_future_sequence 'My::DB::fetch' =>
		Future->done('first'),
		Future->fail('second_fails');

	is My::DB::fetch()->get, 'first', 'pre-built done Future passed through';
	ok My::DB::fetch()->is_failed,    'pre-built fail Future passed through';

	restore_all();
};

subtest 'mock_future_sequence — mixed plain and Future items' => sub {
	mock_future_sequence 'My::DB::fetch' =>
		'plain_value',
		Future->done('pre_built');

	is My::DB::fetch()->get, 'plain_value', 'plain value wrapped in done';
	is My::DB::fetch()->get, 'pre_built',   'pre-built Future used as-is';

	restore_all();
};

subtest 'mock_future_sequence — recorded in diagnose_mocks' => sub {
	mock_future_sequence 'My::DB::fetch' => 1;

	my $diag = diagnose_mocks();
	is $diag->{'My::DB::fetch'}{layers}[0]{type},
		'mock_future_sequence', 'type is mock_future_sequence';

	restore_all();
};

# =================================================================
# mock_future_once
# =================================================================

subtest 'mock_future_once — fires once then restores original' => sub {
	mock_future_once 'My::DB::ping' => 'transient';

	my $f = My::DB::ping();
	isa_ok $f, 'Future';
	is $f->get, 'transient', 'first call returns Future-wrapped value';
	is My::DB::ping(), 'real_ping', 'second call uses original';

	restore_all();
};

subtest 'mock_future_once — fires once then restores previous mock' => sub {
	mock_future_return 'My::DB::ping' => 'baseline';
	mock_future_once   'My::DB::ping' => 'temporary';

	is My::DB::ping()->get, 'temporary', 'once fires first';
	is My::DB::ping()->get, 'baseline',  'then reverts to previous mock';

	restore_all();
};

subtest 'mock_future_once — recorded in diagnose_mocks' => sub {
	mock_future_once 'My::DB::ping' => 1;

	my $diag = diagnose_mocks();
	is $diag->{'My::DB::ping'}{layers}[0]{type},
		'mock_future_once', 'type is mock_future_once';

	restore_all();
};

# =================================================================
# async_spy
# =================================================================

# Give fetch a real Future-returning implementation for spy tests
{
	no warnings 'redefine';
	*My::DB::fetch = sub { Future->done('db_result') };
}

subtest 'async_spy — records args and captured Future' => sub {
	my $spy = async_spy 'My::DB::fetch';

	My::DB::fetch('arg1');
	My::DB::fetch('arg2', 'arg3');

	my @calls = $spy->();
	is scalar @calls, 2, 'two calls recorded';

	is $calls[0]{args}[0], 'My::DB::fetch', 'method name in args[0]';
	is $calls[0]{args}[1], 'arg1',          'first arg of call 1';
	is $calls[1]{args}[1], 'arg2',          'first arg of call 2';
	is $calls[1]{args}[2], 'arg3',          'second arg of call 2';

	ok $calls[0]{future}->is_done,   'future captured for call 1';
	is $calls[0]{future}->get, 'db_result', 'future value matches original return';

	restore_all();
};

subtest 'async_spy — original is still called' => sub {
	my $spy = async_spy 'My::DB::fetch';

	my $returned = My::DB::fetch();
	isa_ok $returned, 'Future', 'caller receives the Future';
	is $returned->get, 'db_result', 'caller sees the real resolved value';

	restore_all();
};

subtest 'async_spy — longhand target form' => sub {
	my $spy = async_spy('My::DB', 'fetch');

	My::DB::fetch();
	my @calls = $spy->();
	is scalar @calls, 1, 'longhand form works';

	restore_all();
};

subtest 'async_spy — recorded in diagnose_mocks' => sub {
	my $spy = async_spy 'My::DB::fetch';

	my $diag = diagnose_mocks();
	is $diag->{'My::DB::fetch'}{layers}[0]{type},
		'async_spy', 'type is async_spy';

	restore_all();
};

subtest 'async_spy — participates in assert_call_order' => sub {
	{
		no warnings 'redefine';
		*My::DB::save = sub { Future->done('saved') };
	}

	async_spy 'My::DB::fetch';
	async_spy 'My::DB::save';

	My::DB::fetch();
	My::DB::save();

	assert_call_order('My::DB::fetch', 'My::DB::save');

	restore_all();
};

# =================================================================
# Error cases
# =================================================================

subtest 'error: mock_future_return without target' => sub {
	dies_ok { mock_future_return(undef, 1) } 'undef target croaks';
};

subtest 'error: mock_future_fail without target or message' => sub {
	dies_ok { mock_future_fail(undef, 'msg') } 'undef target croaks';
	dies_ok { mock_future_fail('My::DB::fetch') } 'missing message croaks';
};

subtest 'error: mock_future_sequence without items' => sub {
	dies_ok { mock_future_sequence('My::DB::fetch') } 'no items croaks';
};

subtest 'error: mock_future_once without target' => sub {
	dies_ok { mock_future_once(undef) } 'undef target croaks';
};

done_testing();
