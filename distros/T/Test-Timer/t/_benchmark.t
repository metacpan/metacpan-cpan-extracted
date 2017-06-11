
use strict;
use Test::Fatal; # like
use Test::More;

BEGIN { use_ok('Test::Timer'); }

$Test::Timer::alert = 1;

like(
    exception { Test::Timer::_benchmark( sub { sleep(20); }, 1 ); },
    qr/Execution ran \d+ seconds and exceeded threshold of \d+ seconds and timed out/,
    'Caught timeout exception'
);

$Test::Timer::alert = 6;

like(
    exception { Test::Timer::_benchmark( sub { sleep(20); }, 1 ); },
    qr/Execution ran \d+ seconds and exceeded threshold of \d+ seconds and timed out/,
    'Caught timeout exception'
);

done_testing();
