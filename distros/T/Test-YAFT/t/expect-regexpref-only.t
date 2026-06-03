#!/usr/bin/env perl

use v5.14;
use warnings;

use require::relative q (test-helper.pl);

assume_test_yaft_exports expect_regexpref_only
	=> by_default => 1
	=> on_demand  => 1
	=> by_tag     => [qw [all default expectations]]
	;

assume_yaft_dump q (Dumper should produce expect_regexpref_only (qr (foo)))
	=> got { expect_regexpref_only (qr (foo)) }
	=> expect => <<'END_OF_EXPECTED'
expect_regexpref_only (
  qr/foo/u,
)
END_OF_EXPECTED
	;

had_no_warnings;
done_testing;
