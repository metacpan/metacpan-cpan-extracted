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
use WebService::Shippo;

my @tests = (
    testIterator => sub {
        my $it = Shippo::Addresses->iterate( results => 3 );
        for ( my $i = 0; $i < 6; $i++ ) {
            my ( $address ) = $it->();
            ok( $address->object_id, __TEST__ );
        }
    },
);

SKIP: {
    skip '(no Shippo API key defined)', 1
        unless Shippo->api_key;
    TestHarness->run_tests( \@tests );
}

done_testing();
