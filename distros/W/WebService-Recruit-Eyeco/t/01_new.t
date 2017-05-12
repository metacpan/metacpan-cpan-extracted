#
# Test case for WebService::Recruit::Eyeco
#

use strict;
use Test::More tests => 2;

BEGIN { use_ok('WebService::Recruit::Eyeco'); }

my $obj = new WebService::Recruit::Eyeco();
ok( ref $obj, 'new WebService::Recruit::Eyeco()');

1;
