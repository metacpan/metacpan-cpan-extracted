
use strict;
use Test::Fatal; # like
use Test::More;

use Test::Timer;

$Test::Timer::alarm = 1;

like(
    exception { Test::Timer::_benchmark( sub { sleep(20); }, 1 ); },
    qr/2/,
    'Caught timeout exception'
);

$Test::Timer::alarm = 2;

like(
    exception { Test::Timer::_benchmark( sub { sleep(20); }, 1 ); },
    qr/3/,
    'Caught timeout exception'
);

ok( Test::Timer::_benchmark( sub { sleep(1); } ) );

ok( Test::Timer::_benchmark( sub { sleep(2); }, 1 ) );

done_testing();
