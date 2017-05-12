use warnings;
use strict;

use Test::HTTP '-syntax', tests => 2;

test_http "Socialtext" {
    >> GET http://www.socialtext.com/

    << 200
}

# Method in a variable should be OK, too.

test_http "method in variable" {
    my $method = 'GET';

    >> $method http://www.socialtext.com/

    << 200
}
