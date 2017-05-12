#
# Test case for WebService::Recruit::AbRoad
#

use strict;
use Test::More tests => 2;

BEGIN { use_ok('WebService::Recruit::AbRoad'); }

my $obj = new WebService::Recruit::AbRoad();
ok( ref $obj, 'new WebService::Recruit::AbRoad()');

1;
