use strict;
use Test::More;
BEGIN { use_ok("Text::CaboCha") }

can_ok("Text::CaboCha", qw/new parse parse_from_node/);

done_testing;