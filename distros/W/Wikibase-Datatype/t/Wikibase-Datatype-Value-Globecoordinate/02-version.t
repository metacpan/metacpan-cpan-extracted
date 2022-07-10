use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Value::Globecoordinate;

# Test.
is($Wikibase::Datatype::Value::Globecoordinate::VERSION, 0.19, 'Version.');
