#!perl -w

use strict;
use Test::More tests => 1;

use Test::LeakTrace;

sub foo{
	my $foo = 42;
	my @array;
	my %hash;

	[\$foo, \@array, \%hash];
}


no_leaks_ok \&foo, 'PADSTALE sv is not a memory leak';
