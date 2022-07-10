use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Struct::Value::Globecoordinate;

# Test.
is($Wikibase::Datatype::Struct::Value::Globecoordinate::VERSION, 0.09, 'Version.');
