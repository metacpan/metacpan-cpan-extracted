use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Value::Lexeme::Wikidata::Dorota;

# Test.
is($Test::Shared::Fixture::Wikibase::Datatype::Value::Lexeme::Wikidata::Dorota::VERSION, 0.33, 'Version.');
