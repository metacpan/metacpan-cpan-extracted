#!/usr/bin/env perl

use v5.14;
use warnings;

use require::relative "test-helper.pl";

subtest "when getting fail" => sub {
	Test::Tester::check_test
		sub {
			nok "should just pass"
				=> got    => 0
				;
		},
		{
			ok          => 1,
			actual_ok   => 1,
			name        => 'should just pass',
			diag        => '',
		}
	;
};

subtest "when getting true" => sub {
	Test::Tester::check_test
		sub {
			nok "should just fail"
				=> got    => 1
				;
		},
		{
			ok          => 0,
			actual_ok   => 0,
			name        => 'should just fail',
			diag        => '',
		}
	;
};

had_no_warnings;

done_testing;

