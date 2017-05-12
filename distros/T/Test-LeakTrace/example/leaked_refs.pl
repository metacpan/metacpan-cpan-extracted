#!perl -w

use strict;
use Test::LeakTrace;
use Data::Dumper;

my @refs = leaked_refs{
	my %a;
	my %b;

	$a{b} = \%b;
	$b{a} = \%a;
};
print Data::Dumper->Dump([\@refs], ['*leaked']);

