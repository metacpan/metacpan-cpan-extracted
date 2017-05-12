package MyTest::PutItAllTogether;

use strict;
use warnings;

use Test::Kit;

include 'Test::More' => {
    exclude => [ 'fail' ],
    rename => {
        is => 'equal',
    },
};

include 'Test::Warn';

include 'Test::Exception';

1;
