use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Toolforge::MixNMatch::Struct::User');
}

# Test.
require_ok('Toolforge::MixNMatch::Struct::User');
