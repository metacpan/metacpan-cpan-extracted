use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Property::Wikidata::InstanceOf;

# Test.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Property::Wikidata::InstanceOf->new;
isa_ok($obj, 'Test::Shared::Fixture::Wikibase::Datatype::Property::Wikidata::InstanceOf');
