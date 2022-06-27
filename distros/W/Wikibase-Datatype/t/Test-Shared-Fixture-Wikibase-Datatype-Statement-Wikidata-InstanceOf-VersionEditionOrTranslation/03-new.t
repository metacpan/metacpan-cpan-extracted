use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::InstanceOf::VersionEditionOrTranslation;

# Test.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::InstanceOf::VersionEditionOrTranslation->new;
isa_ok($obj, 'Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::InstanceOf::VersionEditionOrTranslation');
