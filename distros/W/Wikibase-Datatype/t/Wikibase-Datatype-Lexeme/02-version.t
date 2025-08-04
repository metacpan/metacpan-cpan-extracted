use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Lexeme;

# Test.
is($Wikibase::Datatype::Lexeme::VERSION, 0.39, 'Version.');
