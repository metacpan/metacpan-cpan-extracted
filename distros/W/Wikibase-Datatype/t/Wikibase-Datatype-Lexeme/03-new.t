use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Lexeme;

# Test.
my $obj = Wikibase::Datatype::Lexeme->new;
isa_ok($obj, 'Wikibase::Datatype::Lexeme');

