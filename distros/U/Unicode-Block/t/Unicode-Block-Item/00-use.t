# Pragmas.
use strict;
use warnings;

# Modules.
use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Unicode::Block::Item');
}

# Test.
require_ok('Unicode::Block::Item');
