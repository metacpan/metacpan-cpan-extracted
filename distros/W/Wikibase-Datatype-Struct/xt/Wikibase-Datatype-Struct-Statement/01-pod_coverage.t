use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Wikibase::Datatype::Struct::Statement', 'Wikibase::Datatype::Struct::Statement is covered.');
