use warnings;
use strict;

use Test::HTTP '-syntax', tests => 2;

test_http "Socialtext" {
    >> GET http://neverssl.com/

    << 200
}

# Method in a variable should be OK, too.

test_http "method in variable" {
    my $method = 'GET';

    >> $method http://neverssl.com/

    << 200
}
