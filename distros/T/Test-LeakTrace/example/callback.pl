#!perl -w

use strict;
use Test::LeakTrace;
use Data::Dumper;


leaktrace{
	my %a;
	my %b;

	$a{b} = \%b;
	$b{a} = \%a;

} sub {
	my($ref, $file, $line) = @_;
	print "#line $line $file\n";
	print Dumper($ref);
};

