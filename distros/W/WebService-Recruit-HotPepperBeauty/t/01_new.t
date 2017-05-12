#
# Test case for WebService::Recruit::HotPepperBeauty
#

use strict;
use Test::More tests => 2;

BEGIN { use_ok('WebService::Recruit::HotPepperBeauty'); }

my $obj = new WebService::Recruit::HotPepperBeauty();
ok( ref $obj, 'new WebService::Recruit::HotPepperBeauty()');

1;
