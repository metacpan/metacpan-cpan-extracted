#!/usr/bin/perl -w
## Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl t02.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;


{	package Exp;
	use mem;

	our @EXPORT;
	our @EXPORT_OK;


	sub one () {
		return "is_one";
	}

	our $two="is_two";

	our %three=(is_three=>3);

	our @four=("is", "four", 4);

	sub five() { return "is_five" }

	use Xporter(@EXPORT=qw(one $two %three @four), 
						@EXPORT_OK=qw(&five));


1}


package main;

use Test::More tests=>3;

use Exp qw(! $two five);

my $val = eval '$three{is_three}';

ok(!(defined $val), "val was unavailable(negate default export)" );

ok(five eq "is_five", "still got five");
ok($two eq "is_two", "and two");

