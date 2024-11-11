use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Property::Wikidata::InstanceOf;

# Test.
is($Test::Shared::Fixture::Wikibase::Datatype::Property::Wikidata::InstanceOf::VERSION, 0.34, 'Version.');
