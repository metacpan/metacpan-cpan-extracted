use strict;
use warnings;
use Test::More;

use Test::Fatal; # like

use_ok('Test::Timer');

time_nok( sub { sleep(2); }, 1, 'Failing test' );

$Test::Timer::alert = 6;

like(
    exception { time_nok(sub { sleep(1); } ); },
    qr/^Insufficient number of parameters/,
    'Dying test, missing argument'
);

done_testing();
