## no critic (RequireVersionVar RequireExplicitPackage RequireEndWithOne)

use warnings;
use strict;
use Test::Fatal;    # like
use Test::More;     # ok

use Test::Timer;

use FindBin qw($Bin);
use lib "$Bin/../t";

use Test::Timer::Test qw(_sleep);

$Test::Timer::alarm = 2;

ok( !Test::Timer::_runtest(), 'testing without parameters' );

ok( !Test::Timer::_runtest( sub { return; }, undef ),
    'testing with single parameters' );

ok( !Test::Timer::_runtest( sub { return; }, 1, undef ),
    'testing with two parameters' );

ok( !Test::Timer::_runtest( sub { return; }, 10, 1 ),
    'testing with two thresholds in wrong order'
);

done_testing();
