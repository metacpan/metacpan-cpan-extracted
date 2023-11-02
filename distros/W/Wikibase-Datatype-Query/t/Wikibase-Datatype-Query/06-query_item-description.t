use strict;
use warnings;

use Test::More 'tests' => 4;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog;
use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Query;

# Common.
my $item = Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog->new;

# Test.
my $obj = Wikibase::Datatype::Query->new;
my $ret = $obj->query_item($item, 'description:en');
is($ret, 'domestic animal', 'Get Item English description (domestic animal).');

# Test.
$obj = Wikibase::Datatype::Query->new;
my @ret = $obj->query_item($item, 'description');
is_deeply(\@ret, [decode_utf8('domácí zvíře'), 'domestic animal'],
	'Get Item all description values ([domácí zvíře, domestic animal]).');

# Test.
$obj = Wikibase::Datatype::Query->new;
$ret = $obj->query_item($item, 'description');
is($ret, decode_utf8('domácí zvíře'), 'Get Item first description value (domácí zvíře).');
