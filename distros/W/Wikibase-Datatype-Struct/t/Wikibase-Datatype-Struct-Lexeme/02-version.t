use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Struct::Lexeme;

# Test.
is($Wikibase::Datatype::Struct::Lexeme::VERSION, 0.13, 'Version.');
