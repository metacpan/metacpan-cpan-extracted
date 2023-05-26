use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('WQS::SPARQL::Query::Count');
}

# Test.
require_ok('WQS::SPARQL::Query::Count');
