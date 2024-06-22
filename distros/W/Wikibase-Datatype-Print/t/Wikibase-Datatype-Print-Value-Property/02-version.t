use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Print::Value::Property;

# Test.
is($Wikibase::Datatype::Print::Value::Property::VERSION, 0.17, 'Version.');
