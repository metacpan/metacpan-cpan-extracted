use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun;
use Wikibase::Datatype::Lexeme;

# Test.
my $obj = Wikibase::Datatype::Lexeme->new;
my $ret = $obj->ns;
is($ret, 146, 'Get default namespace (146).');

# Test.
$obj = Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun->new;
$ret = $obj->ns;
is($ret, 146, 'Get namespace (146).');
