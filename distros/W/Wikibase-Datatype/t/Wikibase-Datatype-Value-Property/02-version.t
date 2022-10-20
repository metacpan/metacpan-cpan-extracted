use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Value::Property;

# Test.
is($Wikibase::Datatype::Value::Property::VERSION, 0.22, 'Version.');
