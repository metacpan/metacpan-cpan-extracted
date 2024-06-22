use strict;
use warnings;

use Readonly;
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Wikibase::Datatype::Print::Texts qw(texts);

Readonly::Hash our %EN_TEXTS => (
	'aliases' => 'Aliases',
	'data_type' => 'Data type',
	'date_of_modification' => 'Date of modification',
	'description' => 'Description',
	'forms' => 'Forms',
	'glosses' => 'Glosses',
	'grammatical_features' => 'Grammatical features',
	'id' => 'Id',
	'label' => 'Label',
	'language' => 'Language',
	'last_revision_id' => 'Last revision id',
	'lemmas' => 'Lemmas',
	'lexical_category' => 'Lexical category',
	'ns' => 'NS',
	'page_id' => 'Page id',
	'rank_deprecated' => 'deprecated',
	'rank_normal' => 'normal',
	'rank_preferred' => 'preferred',
	'references' => 'References',
	'representation' => 'Representation',
	'senses' => 'Senses',
	'sitelinks' => 'Sitelinks',
	'statements' => 'Statements',
	'title' => 'Title',
	'value_no' => 'no value',
	'value_unknown' => 'unknown value',
);

# Test.
my $ret_hr = texts('en');
is_deeply(
	$ret_hr,
	\%EN_TEXTS,
	'Get texts (English).',
);

# Test.
$ret_hr = texts();
is_deeply(
	$ret_hr,
	\%EN_TEXTS,
	'Get texts (default - english).',
);
