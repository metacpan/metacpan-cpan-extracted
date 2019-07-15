use 5.012;
use warnings;

BEGIN {
    unless ($ENV{TEST_FULL}) {
        say "1..0 # SKIP set TEST_FULL=1 to enable this test";
        exit;
    }
}

use lib 't';
use MyTest;

1;