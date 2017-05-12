#!perl -w
use strict;

BEGIN{ $ENV{PERL_MACRO_DEBUG} = 2 }
use macro::compiler
	add    => sub{ $_[0] + $_[1] },
	square => sub{ $_[0] + $_[0] },
	say    => sub{ print @_, "\n" },
	my_or  => sub{ $_[0] or $_[1] },
;

say( add(10-1, add(1, 2)) );
say( my_or(0, square(10)) );

say();
say("foo");
say("foo", "bar");
