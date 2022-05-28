use strict;
use warnings;

use Test::More 'tests' => 7;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Reference::Wikidata::ReferenceURL;
use Wikibase::Datatype::Reference;

# Test.
my $obj = Wikibase::Datatype::Reference->new(
	'snaks' => [],
);
my $ret_ar = $obj->snaks;
is_deeply($ret_ar, [], 'Get default snaks.');

# Test.
$obj = Test::Shared::Fixture::Wikibase::Datatype::Reference::Wikidata::ReferenceURL->new;
$ret_ar = $obj->snaks;
is(@{$ret_ar}, 2, 'Number of snaks.');
is($ret_ar->[0]->datavalue->value, 'https://skim.cz', 'First snak value.');
is($ret_ar->[0]->property, 'P854', 'First snak property.');
is($ret_ar->[1]->datavalue->value, '+2013-12-07T00:00:00Z', 'Second snak value.');
is($ret_ar->[1]->property, 'P813', 'Second snak property.');
