#
# Test case for WebService::Recruit::CarSensor
#

use strict;
use Test::More tests => 2;

BEGIN { use_ok('WebService::Recruit::CarSensor'); }

my $obj = new WebService::Recruit::CarSensor();
ok( ref $obj, 'new WebService::Recruit::CarSensor()');

1;
