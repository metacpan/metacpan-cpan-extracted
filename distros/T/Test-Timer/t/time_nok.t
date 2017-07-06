use strict;
use warnings;
use Test::More;

use Test::Fatal; # like

use_ok('Test::Timer');

time_nok( sub { sleep(2); }, 1, 'Failing test' );

done_testing();
