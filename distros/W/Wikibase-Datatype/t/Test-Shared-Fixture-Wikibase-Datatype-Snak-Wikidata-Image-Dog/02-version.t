use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::Image::Dog;

# Test.
is($Test::Shared::Fixture::Wikibase::Datatype::Snak::Wikidata::Image::Dog::VERSION, 0.38, 'Version.');
