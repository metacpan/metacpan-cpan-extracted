use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::Retrieved::Fixture1;

# Test.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::Retrieved::Fixture1->new;
isa_ok($obj, 'Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::Retrieved::Fixture1');
