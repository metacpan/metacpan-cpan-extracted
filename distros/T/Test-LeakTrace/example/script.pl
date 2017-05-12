#!perl -w

use strict;
use Test::LeakTrace::Script -lines;

use Scalar::Util qw(weaken);

{
	my %a;
	my %b;

	$a{b} = \%b;
	$b{a} = \%a;
}

print "done.\n";
