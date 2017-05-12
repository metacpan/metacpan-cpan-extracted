#
# Test case for WebService::Recruit::Akasugu
#

use strict;
use Test::More tests => 2;

BEGIN { use_ok('WebService::Recruit::Akasugu'); }

my $obj = new WebService::Recruit::Akasugu();
ok( ref $obj, 'new WebService::Recruit::Akasugu()');

1;
