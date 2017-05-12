#
# Test case for WebService::Recruit::Shingaku
#

use strict;
use Test::More tests => 2;

BEGIN { use_ok('WebService::Recruit::Shingaku'); }

my $obj = new WebService::Recruit::Shingaku();
ok( ref $obj, 'new WebService::Recruit::Shingaku()');

1;
