use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Unicode::Block::Ascii');
}

# Test.
require_ok('Unicode::Block::Ascii');
