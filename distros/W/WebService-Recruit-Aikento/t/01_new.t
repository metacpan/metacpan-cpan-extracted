#
# Test case for WebService::Recruit::Aikento
#

use strict;
use Test::More tests => 2;

BEGIN { use_ok('WebService::Recruit::Aikento'); }

my $obj = new WebService::Recruit::Aikento();
ok( ref $obj, 'new WebService::Recruit::Aikento()');

1;
