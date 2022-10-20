use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog;
use Wikibase::Datatype::Print::Utils qw(print_sitelinks);
use Wikibase::Datatype::Print::Sitelink;

# Test.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog->new;
my @ret = print_sitelinks($obj, {},
	\&Wikibase::Datatype::Print::Sitelink::print);
is_deeply(
	\@ret,
	[
		'Sitelinks:',
		'  Dog (enwiki)',
	],
	'Print sitelinks test.',
);
