use strict;
use Test::More;
require "t/lb.pl";

BEGIN { plan tests => 2 }

dotest('uri', 'uri.break', ColumnsMax => 1, Prep => 'BREAKURI');
dotest('uri', 'uri.nonbreak', ColumnsMax => 1, Prep => 'NONBREAKURI');
## Obsoleted options
#dotest('uri', 'uri.break', ColumnsMax => 1, UserBreaking => ['BREAKURI']);
#dotest('uri', 'uri.nonbreak', ColumnsMax => 1, UserBreaking => ['NONBREAKURI']);


1;

