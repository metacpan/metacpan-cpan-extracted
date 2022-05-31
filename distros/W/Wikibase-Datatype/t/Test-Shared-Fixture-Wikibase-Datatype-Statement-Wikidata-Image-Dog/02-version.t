use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::Image::Dog;

# Test.
is($Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::Image::Dog::VERSION, 0.12, 'Version.');
