use strict;
use warnings;

use Test::More;

BEGIN {
    if (! $ENV{PI_BOARD}){
        plan skip_all => "not a Pi board";
        exit;
    }
}

BEGIN { use_ok('WiringPi::API') };

done_testing();
