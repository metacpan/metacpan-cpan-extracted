#!perl -w
use strict;
use Benchmark qw();
our $t;
BEGIN{	$t = Benchmark->new; }
END{	print 'time: ', Benchmark->new->timediff($t)->timestr, "\n"; }

use Devel::LeakTrace::Fast;

use ExtUtils::MakeMaker (); # a large module

{
	my %hash;
	for(1 .. 1000){
		$hash{$_}++;
		$hash{$_}++;
	}

	my %a;
	my %b;

	$a{b} = \%a;
	$b{a} = \%b;
}
