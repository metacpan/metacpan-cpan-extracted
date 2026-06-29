use strict;
use warnings;

use Test::More;

BEGIN {
	use_ok 'constant::string::uc' => qw/foo Bar BAZ/;
}

is( FOO, 'foo', 'FOO is a constant with the value "foo"' );
is( BAR, 'Bar', 'BAR is a constant with the value "Bar"' );
is( BAZ, 'BAZ', 'BAZ is a constant with the value "BAZ"' );

done_testing;
