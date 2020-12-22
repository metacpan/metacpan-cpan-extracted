use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Toolforge::MixNMatch::Struct::YearMonth');
}

# Test.
require_ok('Toolforge::MixNMatch::Struct::YearMonth');
