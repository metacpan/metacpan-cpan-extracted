#!/usr/bin/perl 
use warnings; use strict;

{ package sx;
	use mem;
	our @EXPORT;

	sub s1 () {return 111}
	sub s2 () {return 222}
	sub s3 () {return 333}
	sub s4 () {return 444}
	sub s5 () {return 555}
	use Xporter(@EXPORT=qw(s1 s2 s3 s4 s5));
}

{	package vx;
	use mem;
	use sx;
	our @EXPORT;
	our ($a1, $a2, $a3, $a4, $a5);

	($a1, $a2, $a3, $a4, $a5) = (s1, s2, s3, s4, s5);

	use Xporter(@EXPORT=qw($a1 $a2 $a3 $a4 $a5));
}

package main;  use warnings; use strict;
use Test::More tests=>3;
use vx;

ok($a1==111, "s1->a1 propagation");
ok($a3==333, "s3->a3 propagation");
ok($a5==555, "s5->a5 propagation");
