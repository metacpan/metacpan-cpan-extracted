#
# pass this test or test no more!
#
# or
#
# stop the scrollage on the smokers.
#
use strict;
use warnings;
use MyTest;

BEGIN {
    BAIL_OUT 'UUID.pm not loaded'
        unless use_ok 'UUID';
}

pass 'loaded';

done_testing;
