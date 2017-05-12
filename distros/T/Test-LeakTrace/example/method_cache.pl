#!perl -w

use strict;
use Test::LeakTrace;

{
	package Base;

	sub hello{
		print "Hello, world!\n";
	}

	package Derived;
	our @ISA = qw(Base);
}

leaktrace{
	Derived->hello();
} -verbose;

