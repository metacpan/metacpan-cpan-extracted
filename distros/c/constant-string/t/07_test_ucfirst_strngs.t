use strict;
use warnings;

use Test::More;

BEGIN {
	use_ok 'constant::string::ucfirst' => qw/foo Bar BAZ/;
}

is( Foo, 'foo', 'Foo is a constant with the value "foo"' );
is( Bar, 'Bar', 'Bar is a constant with the value "Bar"' );
is( BAZ, 'BAZ', 'Baz is a constant with the value "BAZ"' );

done_testing;
