package
	Foo;

use strict;
use warnings;

sub my_method :method{}

sub f{
	my_method();
	print "Hello, world!\n";
}

1;
