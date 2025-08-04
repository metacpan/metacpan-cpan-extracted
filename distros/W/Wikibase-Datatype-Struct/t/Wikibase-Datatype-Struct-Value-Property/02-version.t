use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Struct::Value::Property;

# Test.
is($Wikibase::Datatype::Struct::Value::Property::VERSION, 0.15, 'Version.');
