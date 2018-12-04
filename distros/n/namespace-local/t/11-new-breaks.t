#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

require namespace::local;

can_ok "namespace::local::_izer", "new";

throws_ok {
    namespace::local::_izer->new
} qr/arget package/, "can't go without a target package";

lives_ok {
    namespace::local::_izer->new( target => "main" );
} "with target = ok";

done_testing;
