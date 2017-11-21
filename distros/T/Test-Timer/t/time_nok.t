use strict;
use warnings;
use Test::More;

use Test::Fatal; # like

use FindBin qw($Bin);
use lib "$Bin/../t";

use Test::Timer::Test qw(_sleep);

use_ok('Test::Timer');

time_nok( sub { _sleep(2); }, 1, 'Failing test' );

done_testing();
