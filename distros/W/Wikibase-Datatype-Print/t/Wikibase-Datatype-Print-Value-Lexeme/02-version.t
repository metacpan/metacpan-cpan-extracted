use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Print::Value::Lexeme;

# Test.
is($Wikibase::Datatype::Print::Value::Lexeme::VERSION, 0.16, 'Version.');
