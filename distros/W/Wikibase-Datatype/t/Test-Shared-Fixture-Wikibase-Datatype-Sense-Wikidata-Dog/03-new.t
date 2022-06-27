use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Sense::Wikidata::Dog;

# Test.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Sense::Wikidata::Dog->new;
isa_ok($obj, 'Test::Shared::Fixture::Wikibase::Datatype::Sense::Wikidata::Dog');
