package MyTest::Exclude;

use strict;
use warnings;

use Test::Kit;

include 'Test::More' => {
    exclude => [ 'pass', 'fail' ],
};

1;
