#!perl -I.

use Test::MultiFork;
use Test::Simple;
use Time::HiRes qw(sleep);

FORK_ab2c3:

import Test::Simple tests => 3;

d:
	die;
a:
	ok(1, "one$$");
	ok(2, "two$$");
	ok(3, "three$$");
b:
	ok(1, "one$$");
	ok(2, "two$$");
c:	
	ok(1, "one$$");
b:
	ok(3, "three$$");
c:
	ok(2, "two$$");
	ok(3, "three$$");
	


