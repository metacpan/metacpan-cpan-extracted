#!/usr/bin/env perl

use v5.14;
use warnings;

use require::relative q (test-helper.pl);

assume_test_yaft_exports expect_listmethods
	=> by_default => 1
	=> on_demand  => 1
	=> by_tag     => [qw [all default expectations]]
	;

assume_yaft_dump q (Dumper should produce expect_listmethods ([q (foo), 42]))
	=> got { expect_listmethods ([q (foo), 42]) }
	=> expect => <<'END_OF_EXPECTED'
expect_listmethods (
  [
    'foo',
    42
  ],
)
END_OF_EXPECTED
	;

had_no_warnings;
done_testing;
