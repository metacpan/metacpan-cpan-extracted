use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Print::Value::Globecoordinate;

# Test.
is($Wikibase::Datatype::Print::Value::Globecoordinate::VERSION, 0.17, 'Version.');
