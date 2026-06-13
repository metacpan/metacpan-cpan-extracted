use strict;
use warnings;

use Test::More;

SKIP: {
    skip "not a Pi board", 1 unless $ENV{RPI_BOARD};
    use_ok('WiringPi::API');
}

done_testing();
