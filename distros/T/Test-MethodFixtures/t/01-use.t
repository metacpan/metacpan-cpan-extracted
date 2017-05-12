use strict;
use warnings;

use Test::More;

BEGIN {

    use_ok $_ foreach qw/
        Test::MethodFixtures
        Test::MethodFixtures::Storage
        /;
}

done_testing();

