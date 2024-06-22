use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Print::Texts qw(text_keys);

# Test.
my @ret = text_keys();
is_deeply(
	\@ret,
	[
		'aliases',
		'data_type',
		'date_of_modification',
		'description',
		'forms',
		'glosses',
		'grammatical_features',
		'id',
		'label',
		'language',
		'last_revision_id',
		'lemmas',
		'lexical_category',
		'ns',
		'page_id',
		'rank_deprecated',
		'rank_normal',
		'rank_preferred',
		'references',
		'representation',
		'senses',
		'sitelinks',
		'statements',
		'title',
		'value_no',
		'value_unknown',
	],
	'Get text keys (default - English).',
);
