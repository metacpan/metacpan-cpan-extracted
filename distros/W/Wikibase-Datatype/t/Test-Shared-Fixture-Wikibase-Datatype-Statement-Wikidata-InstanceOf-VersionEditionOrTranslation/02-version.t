use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::InstanceOf::VersionEditionOrTranslation;

# Test.
is($Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::InstanceOf::VersionEditionOrTranslation::VERSION, 0.23, 'Version.');
