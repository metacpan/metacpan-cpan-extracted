#!/usr/bin/env perl

use v5.14;
use warnings;

use require::relative q (test-helper.pl);

assume_test_yaft_exports ok
	=> by_default => 1
	=> on_demand  => 1
	=> by_tag     => [qw [all default assumptions asserts]]
	;

check_test q (when getting true)
	=> assumption {
		ok q (should just pass)
			=> got    => 1
			;
	}
	=> ok          => 1
	=> actual_ok   => 1
	=> name        => q (should just pass)
	;

check_test q (when getting false)
	=> assumption {
		ok q (should just fail)
			=> got    => 0
			;
	}
	=> ok          => 0
	=> actual_ok   => 0
	=> name        => q (should just fail)
;

had_no_warnings;
done_testing;

