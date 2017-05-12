# Pragmas.
use strict;
use warnings;

# Modules.
use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('WebService::Ares::Standard');
}

# Test.
require_ok('WebService::Ares::Standard');
