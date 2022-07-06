#!/usr/bin/env perl

use v5.14;
use warnings;

use require::relative "test-helper.pl";

subtest "expecting value" => sub {
	Test::Tester::check_test
		sub {
			it "should just pass"
				=> got    => 42
				=> expect => expect_value (42)
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

subtest "failing to expect value" => sub {
	Test::Tester::check_test
		sub {
			it "should just pass"
				=> got    => 1
				=> expect => 42
				;
		},
		{
			ok          => 0,
			actual_ok   => 0,
			name        => 'should just pass',
			diag        => <<'DIAG'
+---+-----+----------+
| Ln|Got  |Expected  |
+---+-----+----------+
*  1|1    |42        *
+---+-----+----------+
DIAG
		}
	;
};

had_no_warnings;

done_testing;
