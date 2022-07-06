#!/usr/bin/env perl

use v5.14;
use warnings;

use require::relative "test-helper.pl";

subtest "should expect different value" => sub {
	Test::Tester::check_test
		sub {
			it "should just pass"
				=> got    => 24
				=> expect => expect_complement (42)
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

subtest "success expectation of something else than boolean true" => sub {
	Test::Tester::check_test
		sub {
			it "should just pass"
				=> got    => 0
				=> expect => ! expect_true
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

subtest "failed expectation of something else than boolean true" => sub {
	Test::Tester::check_test
		sub {
			it "should just fail"
				=> got    => 0
				=> expect => ! expect_false
				;
		},
		{
			ok          => 0,
			actual_ok   => 0,
			name        => 'should just fail',
			diag        => <<'DIAG'
Compared $data
   got : '0'
expect : Different value than: false ('0')
DIAG
		}
	;
};

had_no_warnings;

done_testing;
