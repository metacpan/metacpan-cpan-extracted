use strict;
use vars qw($test $ok $total @foo);
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

$foo[Foo] = "Foo";
$foo[Bar] = "Bar";
$foo[Cat] = "Cat";
$foo[Dog] = "Dog";

#2
(Foo != 0 or Bar != 1 or Cat != 2 or Dog != 3)
	? NOT_OK
	: OK;

#3
($foo[Foo] ne "Foo" or $foo[Bar] ne "Bar" or $foo[Cat] ne "Cat" or $foo[Dog] ne "Dog")
	? NOT_OK
	: OK;

BEGIN { $total = 3; print "1..$total\n" }
