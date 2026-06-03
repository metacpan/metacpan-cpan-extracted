#!/usr/bin/env perl

use v5.14;
use warnings;

use require::relative q (test-helper.pl);

assume_test_yaft_exports expect_value
	=> by_default => 1
	=> on_demand  => 1
	=> by_tag     => [qw [all default expectations]]
	;

assume_yaft_dump q (Dumper should produce expect_value (42))
	=> got { expect_value (42) }
	=> expect => <<'END_OF_EXPECTED'
expect_value (
  42,
)
END_OF_EXPECTED
	;

check_test q (expecting value)
	=> assumption {
		it q (should just pass)
			=> got    => 42
			=> expect => expect_value (42)
			;
	}
	=> ok          => 1
	=> actual_ok   => 1
	=> name        => q (should just pass)
	;

check_test q (failing to expect value)
	=> assumption {
		it q (should just pass)
			=> got    => 1
			=> expect => 42
			;
	}
	=> ok          => 0
	=> actual_ok   => 0
	=> name        => q (should just pass)
	=> diag        => <<'EXPECTED_DIAG'
+---+-----+----------+
| Ln|Got  |Expected  |
+---+-----+----------+
*  1|1    |42        *
+---+-----+----------+
EXPECTED_DIAG
	;

had_no_warnings;
done_testing;
