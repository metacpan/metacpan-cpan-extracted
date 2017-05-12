#!perl -w

use strict;
use Filter::cpp;

#sub say{ print @_, "\n" }
#sub add{ $_[0] + $_[1] }
#use macro say => \&say, add => \&add;

#define add(a, b)       ((a) + (b))
#define say(args...)    print((args), "\n")

say(  "add(40, 2) = ", add(40, 2) );
say( q{add(40, 2)} );
say( q(add(40, 2)) );

