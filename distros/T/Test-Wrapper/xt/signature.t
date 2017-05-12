use strict;
use warnings;

use Test::More;

eval { use Test::Signature; 1 } or do {
    plan skip_all => 'test requires Test::Signature';
    exit;
};

signature_ok();

done_testing;




