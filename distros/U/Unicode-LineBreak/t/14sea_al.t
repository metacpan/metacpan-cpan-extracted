use strict;
use Test::More;
require "t/lb.pl";

BEGIN { plan tests => 1 }

dotest('th', 'th.al', ComplexBreaking => "NO");

1;

