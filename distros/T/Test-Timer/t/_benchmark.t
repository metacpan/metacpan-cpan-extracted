
use strict;
use Test::Fatal; # like
use Test::More;

use Test::Timer;

use FindBin qw($Bin);
use lib "$Bin/../t";

use Test::Timer::Test qw(_sleep);

$Test::Timer::alarm = 2;

like(
    exception { Test::Timer::_benchmark( sub { _sleep(20); }, 1 ); },
    qr/\d+/,
    'Caught timeout exception'
);

ok( Test::Timer::_benchmark( sub { _sleep(1); } ) );

ok( Test::Timer::_benchmark( sub { _sleep(2); }, 1 ) );

done_testing();
