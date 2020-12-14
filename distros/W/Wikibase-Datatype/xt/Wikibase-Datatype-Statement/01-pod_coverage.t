use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Wikibase::Datatype::Statement',
	{ 'also_private' => ['BUILD'] },
	'Wikibase::Datatype::Statement is covered.');
