#!/usr/bin/perl -w
## Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl t04.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;


{	package Exp;
	use mem;

	our @EXPORT;
	our @EXPORT_OK;
	#use mem(@EXPORT=qw(one $two %three @four), 
	#				@EXPORT_OK=qw(&five));


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
use Exp qw(five);

use Test::More tests=>3;

ok(one eq "is_one", "using a default");

sub first_non_default() {
	use Exp qw(five);
	ok(five eq "is_five", "non-default include 1");
}

first_non_default;

sub second_non_default() {
	use Exp qw(five);
	ok(five eq "is_five", "2nd non-default include");
}

second_non_default;

