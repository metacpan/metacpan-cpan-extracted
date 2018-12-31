use strict;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/..";
require "t/lb.pl";

BEGIN { plan tests => 1 }

dotest('th', 'th.al', ComplexBreaking => "NO");

1;

