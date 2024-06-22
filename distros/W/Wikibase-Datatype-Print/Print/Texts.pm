package Wikibase::Datatype::Print::Texts;

use base qw(Exporter);
use strict;
use warnings;

use Readonly;
use Unicode::UTF8 qw(decode_utf8);

Readonly::Array our @EXPORT_OK => qw(text_keys texts);
Readonly::Hash our %TEXTS => (
	'cs' => {
		'aliases' => 'Aliasy',
		'data_type' => decode_utf8('Datový typ'),
		'date_of_modification' => decode_utf8('Datum změny'),
		'description' => 'Popis',
		'forms' => 'Tvary',
		'glosses' => 'Glosy',
		'grammatical_features' => decode_utf8('Gramatické vlastnosti'),
		'id' => 'Id',
		'label' => decode_utf8('Štítek'),
		'language' => 'Jazyk',
		'last_revision_id' => decode_utf8('Id poslední revize'),
		'lemmas' => 'Lemmy',
		'lexical_category' => decode_utf8('Mluvnická kategorie'),
		'ns' => 'NS',
		'page_id' => decode_utf8('Id stránky'),
		'rank_deprecated' => decode_utf8('zavržené'),
		'rank_normal' => decode_utf8('normální'),
		'rank_preferred' => decode_utf8('preferované'),
		'references' => 'Reference',
		'representation' => 'Reprezentace',
		'senses' => decode_utf8('Významy'),
		'sitelinks' => 'Odkazy',
		'statements' => decode_utf8('Výroky'),
		'title' => 'Titul',
		'value_no' => 'bez hodnoty',
		'value_unknown' => decode_utf8('neznámá hodnota'),
	},
	'en' => {
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
	},
);

our $VERSION = 0.17;

sub text_keys {
	return sort keys %{$TEXTS{'en'}};
}

sub texts {
	my $lang = shift;

	if (! defined $lang
		|| ! exists $TEXTS{$lang}) {

		$lang = 'en';
	}

	return $TEXTS{$lang};
}

1;
