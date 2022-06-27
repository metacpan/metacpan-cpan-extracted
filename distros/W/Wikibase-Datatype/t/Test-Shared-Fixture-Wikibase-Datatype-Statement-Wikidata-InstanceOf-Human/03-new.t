use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::InstanceOf::Human;

# Test.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::InstanceOf::Human->new;
isa_ok($obj, 'Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::InstanceOf::Human');
