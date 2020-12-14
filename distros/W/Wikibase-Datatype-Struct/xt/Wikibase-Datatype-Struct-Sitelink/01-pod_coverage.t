use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Wikibase::Datatype::Struct::Sitelink', 'Wikibase::Datatype::Struct::Sitelink is covered.');
