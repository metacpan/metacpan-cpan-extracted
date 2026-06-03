#!/usr/bin/env perl

use v5.14;
use warnings;

use require::relative q (test-helper.pl);

assume_test_yaft_exports expect_false
	=> by_default => 1
	=> on_demand  => 1
	=> by_tag     => [qw [all default expectations]]
	;

assume_yaft_dump q (Dumper should produce expect_false)
	=> got { expect_false }
	=> expect => <<'END_OF_EXPECTED'
expect_false ()
END_OF_EXPECTED
	;

package Testing::Bool_Overload {
	use overload
		bool => sub { 0 },
		fallback => 1,
		;

	sub new {
		return bless {};
	}
}

check_test q (successful validation with false value)
	=> assumption {
		it q (should pass with 0)
			=> got    => 0
			=> expect => expect_false
			;
	}
	=> ok          => 1
	=> actual_ok   => 1
	=> name        => q (should pass with 0)
	;

check_test q (successful validation with empty string)
	=> assumption {
		it q (should pass with empty string)
			=> got    => q ()
			=> expect => expect_false
			;
	}
	=> ok          => 1
	=> actual_ok   => 1
	=> name        => q (should pass with empty string)
	;

check_test q (successful validation with undef)
	=> assumption {
		it q (should pass with undef)
			=> got    { undef }
			=> expect => expect_false
			;
	}
	=> ok          => 1
	=> actual_ok   => 1
	=> name        => q (should pass with undef)
	;

check_test q (failed validation with true value (1))
	=> assumption {
		it q (should fail with 1)
			=> got    => 1
			=> expect => expect_false
			;
	}
	=> ok          => 0
	=> actual_ok   => 0
	=> name        => q (should fail with 1)
	;

check_test q (failed validation with non-empty string)
	=> assumption {
		it q (should fail with non-empty string)
			=> got    => q (false)
			=> expect => expect_false
			;
	}
	=> ok          => 0
	=> actual_ok   => 0
	=> name        => q (should fail with non-empty string)
	;

check_test q (failed validation with reference)
	=> assumption {
		it q (should fail with reference)
			=> got    => []
			=> expect => expect_false
			;
	}
	=> ok          => 0
	=> actual_ok   => 0
	=> name        => q (should fail with reference)
	;

check_test q (successful validation with object overloaded to false)
	=> assumption {
		it q (should pass with object overloaded to false)
			=> got    => Testing::Bool_Overload::->new
			=> expect => expect_false
			;
	}
	=> ok          => 1
	=> actual_ok   => 1
	=> name        => q (should pass with object overloaded to false)
	;

had_no_warnings;
done_testing;
