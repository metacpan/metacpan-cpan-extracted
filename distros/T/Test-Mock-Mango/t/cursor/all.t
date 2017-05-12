#!/usr/bin/env perl

use strict;
use Test::More;
use Mango;

use Test::Mock::Mango;
use Test::Mock::Mango::Cursor;

my $cursor = Test::Mock::Mango::Cursor->new;

subtest 'Blocking syntax' => sub {
	is( ref $cursor->all, 'ARRAY', 'returns array ref' );

	$Test::Mock::Mango::error = 'oh noes';
	$cursor = Test::Mock::Mango::Cursor->new;
	is $cursor->all, undef, 'returns undef as expected';
	is $Test::Mock::Mango::error, undef, 'error reset';
};

subtest 'Non-blocking syntax' => sub {
	$cursor->all(sub {
		my ($cursor, $err, $docs) = @_;
		is( ref $docs, 'ARRAY', 'returns array ref' );
	});

	$Test::Mock::Mango::error = 'oh noes';
	$cursor = Test::Mock::Mango::Cursor->new;
	$cursor->all( sub {
		my ($self,$err,$doc) = @_;
		is $doc, undef, 'returns undef as expected';
		is $err, 'oh noes', 'error returned as expected';
		is $Test::Mock::Mango::error, undef, 'error reset';
	});
};

done_testing();
