#!/usr/bin/env perl

use v5.14;
use warnings;

use require::relative q (test-helper.pl);

assume_test_yaft_exports expect_true
	=> by_default => 1
	=> on_demand  => 1
	=> by_tag     => [qw [all default expectations]]
	;

assume_yaft_dump q (Dumper should produce expect_true)
	=> got { expect_true }
	=> expect => <<'END_OF_EXPECTED'
expect_true ()
END_OF_EXPECTED
	;

package Testing::Bool_Overload {
	use overload bool => sub { 0 };
	sub new { bless {} }
}

check_test q (successful validation with true value)
	=> assumption {
		it q (should pass with 1)
			=> got    => 1
			=> expect => expect_true
			;
	}
	=> ok          => 1
	=> actual_ok   => 1
	=> name        => q (should pass with 1)
	;

check_test q (failed validation with false value)
	=> assumption {
		it q (should fail with 0)
			=> got    => 0
			=> expect => expect_true
			;
	}
	=> ok          => 0
	=> actual_ok   => 0
	=> name        => q (should fail with 0)
	;

check_test q (failed validation with undef)
	=> assumption {
		it q (should fail with undef)
			=> got    { undef }
			=> expect => expect_true
			;
	}
	=> ok          => 0
	=> actual_ok   => 0
	=> name        => q (should fail with undef)
	;

check_test q (failed validation with object overloaded to false)
	=> assumption {
		it q (should fail with object overloaded to false)
			=> got    { Testing::Bool_Overload::->new }
			=> expect => expect_true
			;
	}
	=> ok          => 0
	=> actual_ok   => 0
	=> name        => q (should fail with object overloaded to false)
	;

had_no_warnings;
done_testing;
