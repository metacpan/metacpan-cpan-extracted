package MyTest::SubNameCollideFixed;

use strict;
use warnings;

use Test::Kit;

include 'Test::More';

include 'Test::Simple' => {
    'rename' => { 'ok' => 'test_simple_ok' },
};

1;
