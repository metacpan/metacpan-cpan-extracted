use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Wikibase::Datatype::Struct::Value::Lexeme', 'Wikibase::Datatype::Struct::Value::Lexeme is covered.');
