use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::GivenName::Douglas;

# Test.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::GivenName::Douglas->new;
isa_ok($obj, 'Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::GivenName::Douglas');
