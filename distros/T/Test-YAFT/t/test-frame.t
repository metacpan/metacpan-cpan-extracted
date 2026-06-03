#!/usr/bin/env perl

use v5.14;
use warnings;

use require::relative q (test-helper.pl);

assume_test_yaft_exports test_frame
	=> by_default => 0
	=> on_demand  => 1
	=> by_tag     => [qw [all foundations plumbings]]
	;

use Test::YAFT qw (test_frame);

sub custom_assumption {
	test_frame {
		Test::More::pass q (custom-assumption)
	};
}

check_test q (test_frame() should properly alter $Test::Builder::Level)
	=> assumption {
		custom_assumption
	}
	=> ok   => 1
	=> name => q (custom-assumption)
	;

had_no_warnings;
done_testing;
