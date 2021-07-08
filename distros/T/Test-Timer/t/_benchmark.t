## no critic (RequireVersionVar RequireExplicitPackage RequireEndWithOne)

use warnings;
use strict;
use Test::Fatal;    # like
use Test::More;

use Test::Timer;

use FindBin qw($Bin);
use lib "$Bin/../t";

use Test::Timer::Test qw(_sleep);

# TODO: rename to ALARM to adhere to Perl::Critic policy
#
$Test::Timer::alarm = 2;

like(
    exception {
        Test::Timer::_benchmark( sub { _sleep(20); }, 1 );
    },
    qr/\d+/xsm,
    'Caught timeout exception'
);

ok( Test::Timer::_benchmark( sub { _sleep(1); } ),
    'testing without threshold' );

ok( Test::Timer::_benchmark( sub { _sleep(2); }, 1 ),
    'testing with threshold' );

done_testing();
