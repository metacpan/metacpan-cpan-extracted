use strict;
use warnings;

use Test::More tests => 2;
use Test::Exception;

BEGIN {
    use_ok ('URI');
}

isa_ok(URI->new('tel:+1-201-555-0123'), 'URI::tel');

1;


