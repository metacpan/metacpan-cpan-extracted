use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Value::Lexeme;

# Test.
is($Wikibase::Datatype::Value::Lexeme::VERSION, 0.39, 'Version.');
