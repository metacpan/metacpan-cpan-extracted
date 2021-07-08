## no critic (RequireVersionVar RequireExplicitPackage RequireEndWithOne)

use warnings;
use strict;
use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../t";

use Test::Timer::Test qw(_sleep);

use_ok('Test::Timer');

time_nok( sub { _sleep(10); }, 1, 'Failing test' );

done_testing();
