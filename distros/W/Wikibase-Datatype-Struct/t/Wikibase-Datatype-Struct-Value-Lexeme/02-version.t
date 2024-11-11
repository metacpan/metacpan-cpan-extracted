use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Struct::Value::Lexeme;

# Test.
is($Wikibase::Datatype::Struct::Value::Lexeme::VERSION, 0.13, 'Version.');
