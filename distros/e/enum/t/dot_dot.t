use strict;
use vars qw($test $ok $total);
sub OK { print "ok " . $test++ . "\n" }
sub NOT_OK { print "not ok " . $test++ . "\n"};

BEGIN { $test = 1; $ok=0; $| = 1 }
END { NOT_OK unless $ok }

use enum;

$ok++;
OK;

use enum qw(Foo Bar Cat Dog);
use enum qw(
	:Months_=0 Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec
	:Days_     Sun=0 Mon Tue Wed Thu Fri Sat
	:Letters_=0 A..Z
	:=0
	: A..Z
	Ten=10	Forty=40	FortyOne	FortyTwo
	Zero=0	One			Two			Three=3	Four
	:=100
);

#2
(Letters_A != 0 or Letters_Z != 25)
	? NOT_OK
	: OK;

#3
(A != 0 or Z != 25)
	? NOT_OK
	: OK;

BEGIN { $total = 3; print "1..$total\n" }
