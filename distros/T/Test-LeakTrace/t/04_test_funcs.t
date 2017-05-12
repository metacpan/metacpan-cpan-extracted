#!perl -w

use strict;
use Test::More tests => 8;

use Test::LeakTrace qw(:test);

{
	package Foo;
	sub new{
		return bless {}, shift;
	}
}

no_leaks_ok {
	my %a;
	my %b;

	$a{b} = 1;
	$b{a} = 2;
} 'not leaked';

no_leaks_ok{
	my $o = Foo->new();
	$o->{bar}++;
};

no_leaks_ok{
	# empty
};

leaks_cmp_ok{
	my $a;
	$a++;
} '==', 0;

sub leaked{
	my %a;
	my %b;

	$a{b} = \%b;
	$b{a} = \%a;
}

leaks_cmp_ok \&leaked, '<',  10;
leaks_cmp_ok \&leaked, '<=', 10;
leaks_cmp_ok \&leaked, '>',   0;
leaks_cmp_ok \&leaked, '>=',  1;

