#!/usr/bin/env perl

use Test::More tests => 2;
use Mango;

use Test::Mock::Mango;
use Test::Mock::Mango::Cursor;

my $cursor = Test::Mock::Mango::Cursor->new;

subtest 'Blockin syntax' => sub {
	is $cursor->count, 5, 'returns expected number of results';

	$Test::Mock::Mango::error = 'oh noes';
	$cursor = Test::Mock::Mango::Cursor->new;
	is $cursor->count, undef, 'returns undef as expected';
	is $Test::Mock::Mango::error, undef, 'error reset';
};

subtest 'Non-blocking syntax' => sub {
	$cursor->count( sub {
		my ($cursor, $err, $count) = @_;
		is $count, 5, 'returns 5 as expected';
		is $err, undef, 'no error';
	});

	$Test::Mock::Mango::error = 'oh noes';	
	$cursor->count( sub {
		my ($cursor, $err, $count) = @_;
		is $count, undef, 'returns undef as expected';
		is $err, 'oh noes', 'error returned as expected';
		is $Test::Mock::Mango::error, undef, 'error reset';
	});
};

done_testing();
