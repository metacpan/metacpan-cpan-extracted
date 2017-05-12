
use strict;
use Test::Fatal; # like
use Test::More tests => 3;

BEGIN { use_ok('Test::Timer'); }

$Test::Timer::alert = 1;

like(
    exception { Test::Timer::_benchmark( sub { sleep(20); }, 1 ); },
    qr/Execution exceeded threshold and timed out/,
    'Caught timeout exception'
);

$Test::Timer::alert = 6;

like(
    exception { Test::Timer::_benchmark( sub { sleep(20); }, 1 ); },
    qr/Execution exceeded threshold and timed out/,
    'Caught timeout exception'
);
