#!/usr/bin/env perl

use v5.14;
use warnings;

use require::relative q (test-helper.pl);

assume_test_yaft_exports expect_regexp_only
	=> by_default => 1
	=> on_demand  => 1
	=> by_tag     => [qw [all default expectations]]
	;

assume_yaft_dump q (Dumper should produce expect_regexp_only (qr (foo)))
	=> got { expect_regexp_only (qr (foo)) }
	=> expect => <<'END_OF_EXPECTED'
expect_regexp_only (
  qr/foo/u,
)
END_OF_EXPECTED
	;

had_no_warnings;
done_testing;
