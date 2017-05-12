use warnings;
use strict;

use Test::HTTP '-syntax', tests => 1;
use Test::More;

TODO: {
    local $TODO = 'testing TODO mechanism';

    test_http "Socialtext" {
        >> GET http://www.socialtext.com/

        << 302
    }
}
