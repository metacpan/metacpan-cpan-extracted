use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Form::Wikidata::DogCzechSingular;

# Test.
is($Test::Shared::Fixture::Wikibase::Datatype::Form::Wikidata::DogCzechSingular::VERSION, 0.37, 'Version.');
