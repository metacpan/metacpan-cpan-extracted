#!perl -T

use Test::More tests => 1;

TODO: {
    local $TODO = "Make tests ask for permission before running transcripts";
    ok( 0,       'TODO' );
}
