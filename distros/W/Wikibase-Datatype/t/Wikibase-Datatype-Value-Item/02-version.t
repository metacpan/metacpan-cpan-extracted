use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Value::Item;

# Test.
is($Wikibase::Datatype::Value::Item::VERSION, 0.33, 'Version.');
