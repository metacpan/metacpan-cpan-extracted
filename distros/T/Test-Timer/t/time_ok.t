use strict;
use warnings;
use Test::More;

use Test::Fatal;

use FindBin qw($Bin);
use lib "$Bin/../t";

use Test::Timer::Test qw(_sleep);

use_ok('Test::Timer');

time_ok( sub { _sleep(1); }, 2, 'Passing test' );

done_testing();
