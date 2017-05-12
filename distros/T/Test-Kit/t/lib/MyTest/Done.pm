package MyTest::Done;

use strict;
use warnings;

use Test::Kit;

include 'Test::More' => {
    exclude => [ qw(ok is isnt like unlike cmp_ok can_ok isa_ok new_ok pass fail explain) ],
    rename => { 'done_testing' => 'done' },
};

1;
