#!/usr/bin/env perl

use v5.14;
use warnings;

use require::relative q (test-helper.pl);

check_test q (combine two expectations with '+')
	=> assumption {
		it q (should pass)
			=> got    => q (foo)
			=> expect =>
				+ expect_re (qr [f])
				+ expect_re (qr [o])
			;
	}
	=> ok          => 1
	=> actual_ok   => 1
	=> name        => q (should pass)
	;

check_test q (combine two expectations with '+ !'' )
	=> assumption {
		it q (should pass)
			=> got    => q (foo)
			=> expect =>
				+ expect_re (qr [f])
				+ ! expect_re (qr [b])
			;
	}
	=> ok          => 1
	=> actual_ok   => 1
	=> name        => q (should pass)
	;

check_test q (combine two expectations with '-')
	=> assumption {
		it q (should pass)
			=> got    => q (foo)
			=> expect =>
				+ expect_re (qr [f])
				- expect_re (qr [b])
			;
	}
	=> ok          => 1
	=> actual_ok   => 1
	=> name        => q (should pass)
	;

check_test q (combine two expectations with '+', combined with unary '-')
	=> assumption {
		it q (should pass)
			=> got    => q (foo)
			=> expect =>
				- expect_re (qr [b])
				+ expect_re (qr [f])
			;
	}
	=> ok          => 1
	=> actual_ok   => 1
	=> name        => q (should pass)
	;

had_no_warnings;
done_testing;
