#!perl -w
use strict;

{
	use macro::compiler
		add      => sub{ $_[0] + $_[1] },
		addprint => sub{ warn add($_[0], $_[1]) },
	;

	addprint(5, 10);
}

sub addprint{
	print "out of scope!\n";
}

addprint(5, 10);

{
	use macro::compiler
		addprint => sub{ print $_[0] + $_[1], "\n" };

	addprint(40, 2);
}
