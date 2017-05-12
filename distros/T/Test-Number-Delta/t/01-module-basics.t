use strict;

use Test::More tests => 3;

BEGIN { use_ok('Test::Number::Delta'); }
my @funcs = qw/ delta_ok delta_within delta_not_ok delta_not_within /;

can_ok( 'Test::Number::Delta', @funcs );
can_ok( 'main',                @funcs );

