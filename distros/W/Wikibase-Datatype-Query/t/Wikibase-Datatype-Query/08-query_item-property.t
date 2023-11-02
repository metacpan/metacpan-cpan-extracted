use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog;
use Wikibase::Datatype::Query;

# Common.
my $item = Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog->new;

# Test.
my $obj = Wikibase::Datatype::Query->new;
my $ret = $obj->query_item($item, 'P31');
is($ret, 'Q55983715', 'Get Item P31 value (Q55983715).');

# Test.
$obj = Wikibase::Datatype::Query->new;
my @ret = $obj->query_item($item, 'P31');
is_deeply(\@ret, ['Q55983715'], 'Get Item P31 value (Q55983715).');
