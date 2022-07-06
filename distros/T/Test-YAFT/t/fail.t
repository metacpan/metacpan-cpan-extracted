#!/usr/bin/env perl

use v5.14;
use warnings;

use require::relative "test-helper.pl";

subtest "when just fails" => sub {
	Test::Tester::check_test
		sub {
			fail "when just fails";
		},
		{
			ok          => 0,
			actual_ok   => 0,
			name        => "when just fails",
			diag        => "",
		},
		"when just fails"
	;
};

subtest "when failing with custom diag" => sub {
	Test::Tester::check_test
		sub {
			fail "when failing with custom diag"
				=> diag   => 'custom diag'
				;
		},
		{
			ok          => 0,
			actual_ok   => 0,
			name        => 'when failing with custom diag',
			diag        => 'custom diag',
		},
		"when failing with custom diag"
	;
};

had_no_warnings;

Test::More::done_testing;
