use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Wikibase::Datatype::Value::Time',
	{ 'also_private' => ['BUILD'] },
	'Wikibase::Datatype::Value::Time is covered.');
