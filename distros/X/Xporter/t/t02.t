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
	use mem(@EXPORT=qw(one $two %three @four), 
					@EXPORT_OK=qw(&five));


	sub one () {
		return "is_one";
	}

	our $two="is_two";

	our %three=(is_three=>3);

	our @four=("is", "four", 4);

	sub five() { return "is_five" }

	use Xporter;

1}

package main;

use Test::More tests => 5; #'last_test_to_print';

use Exp qw(five);

ok(one eq "is_one", "test sub");
ok($two eq "is_two", "test scalar");
ok($three{is_three} eq 3, "test hash");
ok(@four+1==$four[2], "test array");
ok(five eq "is_five", "test Exportok");

