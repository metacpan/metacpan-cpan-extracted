use strict;
use warnings;

use Test::More;
use Test::TinyMocker;

eval {unmock};
like( $@, qr{useless use of unmock}, "no call unmock without parameter" );

eval { unmock 'Module::Will' => method 'not_exists' };
like( $@, qr{unkown method}, "no recover nuknown method" );

done_testing;
