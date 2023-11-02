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
my $ret = $obj->query_item($item, 'alias:en');
is($ret, 'domestic dog', 'Get English alias (domestic dog).');

# Test.
$obj = Wikibase::Datatype::Query->new;
my @ret = $obj->query_item($item, 'alias');
is_deeply(
	\@ret, 
	[
		decode_utf8('pes domácí'),
		'domestic dog',
		'Canis lupus familiaris',
		'Canis familiaris',
		'dogs',
		decode_utf8('🐶'),
		decode_utf8('🐕'),
	],
	'Get all alias values ([pes domácí, domestic dog, Canis lupus familiaris, Canis familiaris, dogs, 🐶, 🐕]).',
);

# Test.
$obj = Wikibase::Datatype::Query->new;
$ret = $obj->query_item($item, 'alias');
is($ret, decode_utf8('pes domácí'), 'Get first alias value (pes domácí).');
