use strict;
use warnings;

use Test::More 0.88;

use constant CONST => 123;
use namespace::clean::xs;

my $x = CONST;
is $x, 123;

ok eval("!defined(&CONST)");

done_testing;
