use strict;
use Test::More tests => 2;

BEGIN { use_ok("WSST::SchemaParser"); }

can_ok("WSST::SchemaParser", qw(types parse));

1;
