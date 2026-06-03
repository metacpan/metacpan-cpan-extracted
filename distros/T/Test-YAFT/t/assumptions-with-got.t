#!/usr/bin/env perl

use v5.14;
use  warnings;

use require::relative q (test-helper.pl);

assume_test_yaft_exports got
	=> by_default => 1
	=> on_demand  => 1
	=> by_tag     => [qw [all default utils helpers]]
	;

check_assumptions q (should accept 'got { }' block as value under 'got' parameter)
	=> assumption {
		assumption_under_test q (got { } block)
			=> got    => got { q (foo) }
			=> expect => q (foo)
	}
	=> ok          => 1
	=> actual_ok   => 1
	=> name        => q (got { } block)
	;

check_assumptions q (should recognize 'got { }' block without parameter)
	=> assumption {
		assumption_under_test q (got { } block)
			=> got    { q (foo) }
			=> expect => q (foo)
	}
	=> ok          => 1
	=> actual_ok   => 1
	=> name        => q (got { } block)
	;

check_assumptions q (should test thrown exception when 'got {}' block dies)
	=> assumption {
		assumption_under_test q (got { } block)
			=> got    { die bless [ q (foo) ], q (Foo::Bar) }
			=> throws => expect_isa (q (Foo::Bar))
	}
	=> ok          => 1
	=> actual_ok   => 1
	=> name        => q (got { } block)
	;

check_assumptions q (should fail when expecting 'throws' but code lives)
	=> assumption {
		assumption_under_test q (got { } block)
			=> got { q (foo) }
			=> throws => ignore
	}
	=> ok          => 0
	=> actual_ok   => 0
	=> name        => q (got { } block)
	=> diag        => <<'EXPECTED_DIAG'
Expected to die by lives
EXPECTED_DIAG
	;

check_assumptions q (should fail when not expecting 'throws' but code dies)
	=> assumption {
		assumption_under_test q (got { } block)
			=> got    { die q (foo) }
			=> expect => ignore
	}
	=> ok          => 0
	=> actual_ok   => 0
	=> name        => q (got { } block)
	=> diag        => qr (Expected to live but died)
	;

had_no_warnings;
done_testing;
