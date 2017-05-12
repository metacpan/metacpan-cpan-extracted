# Pragmas.
use strict;
use warnings;

# Modules.
use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('WebService::MorphIO');
}

# Test.
require_ok('WebService::MorphIO');
