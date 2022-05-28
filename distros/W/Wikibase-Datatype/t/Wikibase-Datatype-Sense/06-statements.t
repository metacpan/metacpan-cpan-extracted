use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::InstanceOf::Human;
use Wikibase::Datatype::Sense;

# Test.
my $obj = Wikibase::Datatype::Sense->new;
my $ret_ar = $obj->statements;
is_deeply($ret_ar, [], 'No stateements.');

# Test.
$obj = Wikibase::Datatype::Sense->new(
	'statements' => [
		Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::InstanceOf::Human->new,
	],
);
$ret_ar = $obj->statements;
is(scalar @{$ret_ar}, 1, 'One statement.');
