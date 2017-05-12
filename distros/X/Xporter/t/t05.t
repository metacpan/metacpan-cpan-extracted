#!/usr/bin/perl 
use warnings; use strict;

{ package module_adder; use warnings; use strict;
	use mem; 
	our (@EXPORT, @EXPORT_OK);
	our $lastsum;
	our @lastargs;
	use Xporter(@EXPORT=qw(adder $lastsum @lastargs), 
							@EXPORT_OK=qw(print_last_result));

	sub adder($$) {@lastargs=@_; $lastsum=$_[0]+$_[1]}
	sub print_last_result () {
		if (@lastargs && defined $lastsum){
			sprintf "%s = %s", (join ' + ' , @lastargs), $lastsum;
		}
	}
}

# in using module (same or different file)

package main;  use warnings; use strict;
use Test::More tests=>1;

use module_adder qw(print_last_result);

adder 4,5;

ok(print_last_result eq "4 + 5 = 9", "pod example as test");
