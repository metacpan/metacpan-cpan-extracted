use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Wikibase::Cache::Backend');
}

# Test.
require_ok('Wikibase::Cache::Backend');
