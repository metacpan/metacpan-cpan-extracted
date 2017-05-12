# Pragmas.
use strict;
use warnings;

# Modules.
use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Video::Delay::Array');
}

# Test.
require_ok('Video::Delay::Array');
