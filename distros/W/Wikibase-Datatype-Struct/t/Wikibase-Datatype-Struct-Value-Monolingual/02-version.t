use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Struct::Value::Monolingual;

# Test.
is($Wikibase::Datatype::Struct::Value::Monolingual::VERSION, 0.06, 'Version.');
