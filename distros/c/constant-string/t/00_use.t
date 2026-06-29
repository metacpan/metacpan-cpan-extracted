use strict;
use warnings;

use Test::More;

BEGIN {
	use_ok( 'constant::string', qw/FOO BAR BAZ/ );
	use_ok( 'constant::string::uc', qw/ucfoo ucbar ucbaz/ );
}


done_testing;
