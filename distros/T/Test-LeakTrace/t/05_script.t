#!perl -w

use strict;
use Test::More tests => 1;
BEGIN{
	pass 'script interface';
}

use Test::LeakTrace::Script;

my $i = 0;


for(1 .. 10){
	my @array = (1 .. 10);
	my %hash  = (foo => 'bar');

	$i++;
}

