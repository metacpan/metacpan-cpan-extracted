#
# Test case for WebService::Recruit::AkasuguUchiiwai
#

use strict;
use Test::More tests => 2;

BEGIN { use_ok('WebService::Recruit::AkasuguUchiiwai'); }

my $obj = new WebService::Recruit::AkasuguUchiiwai();
ok( ref $obj, 'new WebService::Recruit::AkasuguUchiiwai()');

1;
