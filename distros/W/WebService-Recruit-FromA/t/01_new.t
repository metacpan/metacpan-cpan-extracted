#
# Test case for WebService::Recruit::FromA
#

use strict;
use Test::More tests => 2;

BEGIN { use_ok('WebService::Recruit::FromA'); }

my $obj = new WebService::Recruit::FromA();
ok( ref $obj, 'new WebService::Recruit::FromA()');

1;
