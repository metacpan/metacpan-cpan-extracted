#!perl -w

use strict;
use Test::More tests => 5;

use Test::LeakTrace;

sub normal{
	my %a;
	my %b;

	$a{b} = 1;
	$b{a} = 2;
}
cmp_ok leaked_count(\&normal), '<=', 0, 'not leaked(1)';
cmp_ok leaked_count(\&normal), '<=', 0, 'not leaked(2)';

sub leaked{
	my %a;
	my %b;

	$a{b} = \%b;
	$b{a} = \%a;
}

cmp_ok leaked_count(\&leaked), '>', 0;

is leaked_count(\&leaked), scalar(leaked_info \&leaked);
is leaked_count(\&leaked), scalar(leaked_refs \&leaked);
