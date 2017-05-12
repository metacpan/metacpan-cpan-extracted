package MyTest::Like;

use strict;
use warnings;

use Test::Kit;

include 'Test::More' => {
    exclude => [ qw(ok is isnt unlike cmp_ok can_ok isa_ok new_ok pass fail explain done_testing) ]
};

1;
