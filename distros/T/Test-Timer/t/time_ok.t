
use strict;
use Test::More tests => 3;

use Test::Fatal;

BEGIN { use_ok('Test::Timer'); }

time_ok( sub { sleep(1); }, 2, 'Passing test' );

like(
    exception { time_nok(sub { sleep(1); } ); },
    qr/^Insufficient number of parameters/,
    'Dying test, missing argument'
);
