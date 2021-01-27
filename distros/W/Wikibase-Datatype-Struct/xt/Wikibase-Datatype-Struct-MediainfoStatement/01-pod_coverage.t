use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Wikibase::Datatype::Struct::MediainfoStatement', 'Wikibase::Datatype::Struct::MediainfoStatement is covered.');
