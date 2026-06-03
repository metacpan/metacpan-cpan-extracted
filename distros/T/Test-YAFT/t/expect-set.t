#!/usr/bin/env perl

use v5.14;
use warnings;

use require::relative q (test-helper.pl);

assume_test_yaft_exports expect_set
	=> by_default => 1
	=> on_demand  => 1
	=> by_tag     => [qw [all default expectations]]
	;

assume_yaft_dump q (Dumper should produce expect_set (1, 2, 3))
	=> got { expect_set (1, 2, 3) }
	=> expect => <<'END_OF_EXPECTED'
expect_set (
  1,
  2,
  3,
)
END_OF_EXPECTED
	;

had_no_warnings;
done_testing;
