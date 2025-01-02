use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Print::Value::Item;

# Test.
is($Wikibase::Datatype::Print::Value::Item::VERSION, 0.18, 'Version.');
