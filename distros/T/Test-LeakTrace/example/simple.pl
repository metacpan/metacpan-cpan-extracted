#!perl -w

use strict;
use Test::LeakTrace;

my($mode) = @ARGV;

leaktrace{
	my %a;
	my %b;

	$a{b} = \%a;
	$b{a} = \%b;
} $mode;
