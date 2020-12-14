use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Wikibase::Datatype::Value::Quantity');
}

# Test.
require_ok('Wikibase::Datatype::Value::Quantity');
