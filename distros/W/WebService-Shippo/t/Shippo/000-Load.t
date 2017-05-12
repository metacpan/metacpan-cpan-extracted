# Not the greatest tests in the world, but more like a starter 
# for 10 influenced by tests of similar calibre (where present)
# in Shippo's own APIs. I want to re-visit these after the first
# gold release to make them more extensive.

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../lib";
use TestHarness;

use_ok( 'WebService::Shippo' );

done_testing();
