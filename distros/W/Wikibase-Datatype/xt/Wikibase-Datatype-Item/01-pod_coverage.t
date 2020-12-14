use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Wikibase::Datatype::Item',
	{ 'also_private' => ['BUILD'] },
	'Wikibase::Datatype::Item is covered.');
