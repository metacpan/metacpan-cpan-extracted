#!perl -w

use strict;
use Test::More 'no_plan'; # I don't know the number of 'ok'

use Test::LeakTrace;

ok defined &leaktrace;

leaktrace{
	my %a = (foo => 42);
	my %b = (bar => 3.14);

	$b{a} = \%a;
	$a{b} = \%b;

	pass 'in leaktrace block';
} sub {
	my($ref, $file, $line) = @_;

	is scalar(@_), 3, 'leaktrace callback args is 3 (svref, file, line)';

	ok ref($ref), ref $ref;
	isnt ref($ref), 'UNKNOWN';
	isnt $file, undef;
	isnt $line, undef;
};

leaktrace{
	my %a = (foo => 42);
	my %b = (bar => 3.14);
} sub {
	fail 'must not be called';
};

