#!/usr/bin/env perl

use v5.14;
use warnings;

use require::relative q (test-helper.pl);

assume_test_yaft_exports cmp_details
	=> by_default => 0
	=> on_demand  => 1
	=> by_tag     => [qw [all foundations plumbings]]
	;

had_no_warnings;
done_testing;
