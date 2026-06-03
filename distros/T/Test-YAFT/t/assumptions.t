#!/usr/bin/env perl

use v5.14;
use warnings;

use require::relative q (test-helper.pl);

assume_test_yaft_exports assume
	=> by_default => 1
	=> on_demand  => 1
	=> by_tag     => [qw [all default assumptions asserts]]
	;

assume_test_yaft_exports it
	=> by_default => 1
	=> on_demand  => 1
	=> by_tag     => [qw [all default assumptions asserts]]
	;

assume_test_yaft_exports there
	=> by_default => 1
	=> on_demand  => 1
	=> by_tag     => [qw [all default assumptions asserts]]
	;

note <<'';
This test tests all assumption functions (with same functionality) Test::YAFT provides:
- it
- there

check_assumptions q (when passing expecting boolean true it should behave like 'ok')
	=> assumption {
		assumption_under_test q (should pass like 'ok')
			=> got    => 1
			=> expect => expect_true
			;
	}
	=> ok          => 1
	=> actual_ok   => 1
	=> name        => q (should pass like 'ok')
	;

check_assumptions q (when failing while expecting 'true' it shouldn't provide implicit diag message)
	=> assumption {
		assumption_under_test q (should fail like 'ok')
			=> got    => 0
			=> expect => expect_true
	}
	=> ok          => 0
	=> actual_ok   => 0
	=> name        => q (should fail like 'ok')
	;

check_assumptions q (when failing while expecting 'false' it shouldn't provide implicit diag message)
	=> assumption {
		assumption_under_test q (should fail like 'nok')
			=> got    => 1
			=> expect => expect_false
	}
	=> ok          => 0
	=> actual_ok   => 0
	=> name        => q (should fail like 'nok')
	;

check_assumptions q (when failing with custom diag (string) it should provide it even when assumption doesn't provide any)
	=> assumption {
		assumption_under_test q (when failing with custom diag)
			=> got    => 1
			=> expect => expect_false
			=> diag   => q (it should not fail)
	}
	=> ok          => 0
	=> actual_ok   => 0
	=> name        => q (when failing with custom diag)
	=> diag        => q (it should not fail)
	;

check_assumptions q (when failing with custom diag (code) it should provide it even when assumption doesn't provide any)
	=> assumption {
		assumption_under_test q (when failing with custom diag)
			=> got    => 1
			=> expect => expect_false
			=> diag   => sub { q (it should not fail), q ( - really not) }
	}
	=> ok          => 0
	=> actual_ok   => 0
	=> name        => q (when failing with custom diag)
	=> diag        => q (it should not fail - really not)
	;

check_assumptions q (assumptions should accept 'Test::Deep' expectations)
	=> assumption {
		assumption_under_test q (pass with Test::Deep::Cmp)
			=> got    => [ 1, 2 ]
			=> expect => Test::Deep::bag (2, 1)
	}
	=> ok          => 1
	=> actual_ok   => 1
	=> name        => q (pass with Test::Deep::Cmp)
	;

check_assumptions q (when failing with 'Test::Deep' expectation it should append 'difference' diag)
	=> assumption {
		assumption_under_test q (when failing with Test::Deep::Cmp)
			=> got    => [ 1, 2, 3 ]
			=> expect => Test::Deep::bag (2, 1)
	}
	=> ok          => 0
	=> actual_ok   => 0
	=> name        => q (when failing with Test::Deep::Cmp)
	=> diag        => <<'EXPECTED_DIAG'
+----+------+----+------------------------+
| Elt|Got   | Elt|Expected                |
+----+------+----+------------------------+
*   0|[     *   0|bless( {                *
*   1|  1,  *   1|  IgnoreDupes => 0,     *
*   2|  2,  *   2|  SubSup => '',         *
*   3|  3   *   3|  val => [              *
*   4|]     *   4|    1,                  *
|    |      *   5|    2                   *
|    |      *   6|  ]                     *
|    |      *   7|}, 'Test::Deep::Set' )  *
+----+------+----+------------------------+
Comparing $data as a Bag
Extra: '3'
EXPECTED_DIAG
	;

check_assumptions q (when failing with 'Test::Deep' expectation and custom diag it should show only custom diag)
	=> assumption {
		assumption_under_test q (when failing with Test::Deep::Cmp)
			=> got    => [ 1, 2, 3 ]
			=> expect => Test::Deep::bag (2, 1)
			=> diag   => q (custom diag)
	}
	=> ok          => 0
	=> actual_ok   => 0
	=> name        => q (when failing with Test::Deep::Cmp)
	=> diag        => q (custom diag)
	;

had_no_warnings;
done_testing;
