use strict;
use warnings;

use Test::More tests => 2;

use constant CONST => 123;
use namespace::clean;

my $x = CONST;
is $x, 123;

ok eval("!defined(&CONST)");
