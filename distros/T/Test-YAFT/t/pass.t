#!/usr/bin/env perl

use v5.14;
use warnings;

use require::relative q (test-helper.pl);

assume_test_yaft_exports pass
	=> by_default => 1
	=> on_demand  => 1
	=> by_tag     => [qw [all default assumptions asserts]]
	;

had_no_warnings;
done_testing;
