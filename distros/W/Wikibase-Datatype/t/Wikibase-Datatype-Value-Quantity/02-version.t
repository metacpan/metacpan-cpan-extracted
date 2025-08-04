use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Value::Quantity;

# Test.
is($Wikibase::Datatype::Value::Quantity::VERSION, 0.39, 'Version.');
