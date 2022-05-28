use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::Retrieved::Fixture1');
}

# Test.
require_ok('Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::Retrieved::Fixture1');
