use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Struct::Value::Quantity;

# Test.
is($Wikibase::Datatype::Struct::Value::Quantity::VERSION, 0.07, 'Version.');
