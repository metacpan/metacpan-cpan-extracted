#!/usr/bin/env perl

use v5.14;
use warnings;

use require::relative q (test-helper.pl);

assume_test_yaft_exports expect_complement
	=> by_default => 1
	=> on_demand  => 1
	=> by_tag     => [qw [all default expectations]]
	;

assume_yaft_dump q (Dumper should produce expect_complement (42))
	=> got { expect_complement (42) }
	=> expect => <<'END_OF_EXPECTED'
expect_complement (
  42,
)
END_OF_EXPECTED
	;

check_test q (should expect different value)
	=> assumption {
		it q (should just pass)
			=> got    => 24
			=> expect => expect_complement (42)
			;
	}
	=> ok          => 1
	=> actual_ok   => 1
	=> name        => q (should just pass)
	;

check_test q (success expectation of something else than boolean true)
	=> assumption {
		it q (should just pass)
			=> got    => 0
			=> expect => ! expect_true
			;
	}
	=> ok          => 1
	=> actual_ok   => 1
	=> name        => q (should just pass)
	;

check_test q (failed expectation of something else than boolean true)
	=> assumption {
		it q (should just fail)
			=> got    => 0
			=> expect => ! expect_false
			;
	}
	=> ok          => 0
	=> actual_ok   => 0
	=> name        => q (should just fail)
	=> diag        => <<'DIAG'
Compared $data
   got : '0'
expect : Different value than: false ('0')
DIAG
	;

had_no_warnings;
done_testing;
