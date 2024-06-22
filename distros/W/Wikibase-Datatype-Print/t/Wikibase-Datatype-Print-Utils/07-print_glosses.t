use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Sense::Wikidata::Dog;
use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Print::Texts qw(texts);
use Wikibase::Datatype::Print::Utils qw(print_glosses);
use Wikibase::Datatype::Print::Value::Monolingual;

# Test.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Sense::Wikidata::Dog->new;
my @ret = print_glosses($obj, { 'texts' => texts() },
	\&Wikibase::Datatype::Print::Value::Monolingual::print);
is_deeply(
	\@ret,
	[
		'Glosses:',
		'  domesticated mammal related to the wolf (en)',
		decode_utf8('  psovitá šelma chovaná jako domácí zvíře (cs)'),
	],
	'Print glosses test.',
);
