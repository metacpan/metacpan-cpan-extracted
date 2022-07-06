#!/usr/bin/env perl

use v5.14;
use warnings;

use require::relative "test-helper.pl";

use Context::Singleton;

contrive foo => value => 10;

subtest "subtest should create its own frame" => sub {
	proclaim foo => 42;

	it "should use value available in inner frame"
		=> got    => deduce ('foo')
		=> expect => 42
		;
};

it "should use value available in outer frame"
	=> got    => deduce ('foo')
	=> expect => 10
	;

Test::Warnings::had_no_warnings;

Test::More::done_testing;

