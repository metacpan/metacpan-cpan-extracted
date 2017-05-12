
use strict;
use Test::More tests => 3;

use Test::Fatal; # like

BEGIN { use_ok('Test::Timer'); }

time_nok( sub { sleep(2); }, 1, 'Failing test' );

$Test::Timer::alert = 6;

like(
    exception { time_nok(sub { sleep(1); } ); },
    qr/^Insufficient number of parameters/,
    'Dying test, missing argument'
);
