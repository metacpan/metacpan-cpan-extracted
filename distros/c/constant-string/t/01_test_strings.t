use strict;
use warnings;

use Test::More;

BEGIN {
	use_ok 'constant::string' => qw/FOO BAR BAZ/;
}

is( FOO, 'FOO', 'FOO is a constant with the value "FOO"' );
is( BAR, 'BAR', 'BAR is a constant with the value "BAR"' );
is( BAZ, 'BAZ', 'BAZ is a constant with the value "BAZ"' );

done_testing;
