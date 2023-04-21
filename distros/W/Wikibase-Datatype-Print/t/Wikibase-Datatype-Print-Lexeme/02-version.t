use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Print::Lexeme;

# Test.
is($Wikibase::Datatype::Print::Lexeme::VERSION, 0.09, 'Version.');
