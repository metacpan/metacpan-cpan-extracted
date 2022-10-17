use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Wikibase::API::Resolve');
}

# Test.
require_ok('Wikibase::API::Resolve');
