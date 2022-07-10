use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Struct::Value::Item;

# Test.
is($Wikibase::Datatype::Struct::Value::Item::VERSION, 0.09, 'Version.');
