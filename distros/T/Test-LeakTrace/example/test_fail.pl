#!perl -w

use strict;

use Test::More tests => 1;
use Test::LeakTrace;

no_leaks_ok{
	diag "in not_leaked";

	my @array;
	push @array, \@array;
};
