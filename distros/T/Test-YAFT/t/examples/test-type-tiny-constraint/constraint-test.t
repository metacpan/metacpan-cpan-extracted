#!/usr/bin/env perl

use v5.14;
use warnings;

use require::relative "test-helper.pl";

use Types::Common::Numeric;

subtest "constraint PositiveOrZeroNum" => sub {
	constraint { Types::Common::Numeric::PositiveOrZeroNum };

	#should_pass(0, PositiveOrZeroNum, "PositiveOrZeroNum (0)");
	#should_pass(100.885, PositiveOrZeroNum, "PositiveOrZeroNum (100.885)");
	#should_fail(-100.885, PositiveOrZeroNum, "PositiveOrZeroNum (-100.885)");
	#should_pass(0.0000000001, PositiveOrZeroNum, "PositiveOrZeroNum (0.0000000001)");

	this_constraint "should accept zero"
		=> value  => 0
		=> expect => expect_true
		;

	this_constraint "should accept positive number"
		=> value  => 100.885
		=> expect => expect_true
		;

	this_constraint "should not accept negative value"
		=> value  => -100.885
		=> throws => expect_failed_constraint_exception ('Must be a number greater than or equal to zero')
		;

	this_constraint "should accept very small positive number"
		=> value => 0.0000000001
		=> expect => expect_true
		;
};

had_no_warnings;

done_testing;
