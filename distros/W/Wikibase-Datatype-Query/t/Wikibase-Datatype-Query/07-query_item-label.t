use strict;
use warnings;

use Test::More 'tests' => 6;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog;
use Test::Shared::Fixture::Wikibase::Datatype::Mediainfo::Commons::ImageOfHuman;
use Wikibase::Datatype::Query;

# Common.
my $item = Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog->new;
my $mediainfo = Test::Shared::Fixture::Wikibase::Datatype::Mediainfo::Commons::ImageOfHuman->new;

# Test.
my $obj = Wikibase::Datatype::Query->new;
my $ret = $obj->query_item($item, 'label:en');
is($ret, 'dog', 'Get Item English label (dog).');

# Test.
$obj = Wikibase::Datatype::Query->new;
my @ret = $obj->query_item($item, 'label:en');
is_deeply(\@ret, ['dog'], 'Get Item all English label values ([dog).');

# Test.
$obj = Wikibase::Datatype::Query->new;
@ret = $obj->query_item($item, 'label');
is_deeply(\@ret, ['pes', 'dog'], 'Get Item all label values ([pes, dog).');

# Test.
$obj = Wikibase::Datatype::Query->new;
$ret = $obj->query_item($item, 'label');
is($ret, 'pes', 'Get Item first label value (pes).');

# Test.
$obj = Wikibase::Datatype::Query->new;
$ret = $obj->query_item($mediainfo, 'label');
is($ret, 'Portrait of Douglas Adams', 'Get Mediainfo first label value (Portrait of Douglas Adams).');
