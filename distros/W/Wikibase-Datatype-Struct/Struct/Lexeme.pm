package Wikibase::Datatype::Struct::Lexeme;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Wikibase::Datatype::Form;
use Wikibase::Datatype::Lexeme;
use Wikibase::Datatype::Struct::Form;
use Wikibase::Datatype::Struct::Language;
use Wikibase::Datatype::Struct::Sense;
use Wikibase::Datatype::Struct::Statement;
use Wikibase::Datatype::Value::Item;

Readonly::Array our @EXPORT_OK => qw(obj2struct struct2obj);

our $VERSION = 0.13;

sub obj2struct {
	my ($obj, $base_uri) = @_;

	if (! defined $obj) {
		err "Object doesn't exist.";
	}
	if (! $obj->isa('Wikibase::Datatype::Lexeme')) {
		err "Object isn't 'Wikibase::Datatype::Lexeme'.";
	}
	if (! defined $base_uri) {
		err 'Base URI is required.';
	}

	my $struct_hr = {
		'type' => 'lexeme',
	};

	# Forms.
	foreach my $form (@{$obj->forms}) {
		$struct_hr->{'forms'} //= [];
		push @{$struct_hr->{'forms'}},
			Wikibase::Datatype::Struct::Form::obj2struct($form, $base_uri);
	}

	# Id.
	if (defined $obj->id) {
		$struct_hr->{'id'} = $obj->id;
	}

	# Last revision id.
	if (defined $obj->lastrevid) {
		$struct_hr->{'lastrevid'} = $obj->lastrevid;
	}

	# Language.
	if (defined $obj->language) {
		$struct_hr->{'language'} = $obj->language;
	}

	# Lemmas.
	foreach my $lemma (@{$obj->lemmas}) {
		$struct_hr->{'lemmas'}->{$lemma->language}
			= Wikibase::Datatype::Struct::Language::obj2struct($lemma);
	}

	# Lexical category.
	if (defined $obj->lexical_category) {
		$struct_hr->{'lexicalCategory'} = $obj->lexical_category;
	}

	# Modified date.
	if (defined $obj->modified) {
		$struct_hr->{'modified'} = $obj->modified;
	}

	# Namespace.
	if (defined $obj->ns) {
		$struct_hr->{'ns'} = $obj->ns;
	}

	# Page id.
	if (defined $obj->page_id) {
		$struct_hr->{'pageid'} = $obj->page_id;
	}

	# Senses.
	foreach my $sense (@{$obj->senses}) {
		$struct_hr->{'senses'} //= [];
		push @{$struct_hr->{'senses'}},
			Wikibase::Datatype::Struct::Sense::obj2struct($sense, $base_uri);
	}

	# Statements.
	foreach my $statement (@{$obj->statements}) {
		$struct_hr->{'claims'}->{$statement->snak->property} //= [];
		push @{$struct_hr->{'claims'}->{$statement->snak->property}},
			Wikibase::Datatype::Struct::Statement::obj2struct($statement, $base_uri);
	}

	# Title.
	if (defined $obj->title) {
		$struct_hr->{'title'} = $obj->title;
	}

	return $struct_hr;
}

sub struct2obj {
	my $struct_hr = shift;

	if (! exists $struct_hr->{'type'} || $struct_hr->{'type'} ne 'lexeme') {
		err "Structure isn't for 'lexeme' type.";
	}

	# Forms.
	my $forms_ar = [];
	foreach my $form_hr (@{$struct_hr->{'forms'}}) {
		push @{$forms_ar}, Wikibase::Datatype::Struct::Form::struct2obj($form_hr);
	}

	# Lemmas.
	my $lemmas_ar = [];
	foreach my $lang (keys %{$struct_hr->{'lemmas'}}) {
		push @{$lemmas_ar}, Wikibase::Datatype::Struct::Language::struct2obj(
			$struct_hr->{'lemmas'}->{$lang},
		);
	}

	# Senses.
	my $senses_ar = [];
	foreach my $sense_hr (@{$struct_hr->{'senses'}}) {
		push @{$senses_ar}, Wikibase::Datatype::Struct::Sense::struct2obj($sense_hr);
	}

	# Statements.
	my $statements_ar = [];
	foreach my $property (keys %{$struct_hr->{'claims'}}) {
		foreach my $claim_hr (@{$struct_hr->{'claims'}->{$property}}) {
			push @{$statements_ar}, Wikibase::Datatype::Struct::Statement::struct2obj(
				$claim_hr,
			);
		}
	}

	my $obj = Wikibase::Datatype::Lexeme->new(
		'forms' => $forms_ar,
		'id' => $struct_hr->{'id'},
		'language' => $struct_hr->{'language'},
		defined $struct_hr->{'lastrevid'} ? ('lastrevid' => $struct_hr->{'lastrevid'}) : (),
		'lemmas' => $lemmas_ar,
		defined $struct_hr->{'lexicalCategory'} ? ('lexical_category' => $struct_hr->{'lexicalCategory'}) : (),
		defined $struct_hr->{'modified'} ? ('modified' => $struct_hr->{'modified'}) : (),
		defined $struct_hr->{'ns'} ? ('ns' => $struct_hr->{'ns'}) : (),
		defined $struct_hr->{'pageid'} ? ('page_id' => $struct_hr->{'pageid'}) : (),
		'senses' => $senses_ar,
		'statements' => $statements_ar,
		defined $struct_hr->{'title'} ? ('title' => $struct_hr->{'title'}) : (),
	);

	return $obj;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Struct::Lexeme - Wikibase lexeme structure serialization.

=head1 SYNOPSIS

 use Wikibase::Datatype::Struct::Lexeme qw(obj2struct struct2obj);

 my $struct_hr = obj2struct($obj, $base_uri);
 my $obj = struct2obj($struct_hr);

=head1 DESCRIPTION

This conversion is between objects defined in Wikibase::Datatype and structures
serialized via JSON to MediaWiki.

=head1 SUBROUTINES

=head2 C<obj2struct>

 my $struct_hr = obj2struct($obj, $base_uri);

Convert Wikibase::Datatype::Lexeme instance to structure.
C<$base_uri> is base URI of Wikibase system (e.g. http://test.wikidata.org/entity/).

Returns reference to hash with structure.

=head2 C<struct2obj>

 my $obj = struct2obj($struct_hr);

Convert structure of lexeme to object.

Returns Wikibase::Datatype::Lexeme instance.

=head1 ERRORS

 obj2struct():
         Base URI is required.
         Object doesn't exist.
         Object isn't 'Wikibase::Datatype::Form'.

 struct2obj():
         Structure isn't for 'lexeme' type.

=head1 EXAMPLE1

=for comment filename=obj2struct_lexeme.pl

 use strict;
 use warnings;

 use Data::Printer;
 use Wikibase::Datatype::Form;
 use Wikibase::Datatype::Lexeme;
 use Wikibase::Datatype::Statement;
 use Wikibase::Datatype::Struct::Lexeme qw(obj2struct);
 use Wikibase::Datatype::Value::Monolingual;

 # Statement.
 my $statement = Wikibase::Datatype::Statement->new(
         # instance of (P31) human (Q5)
         'snak' => Wikibase::Datatype::Snak->new(
                 'datatype' => 'wikibase-item',
                 'datavalue' => Wikibase::Datatype::Value::Item->new(
                         'value' => 'Q5',
                 ),
                 'property' => 'P31',
         ),
 );

 # Form.
 my $form = Wikibase::Datatype::Form->new(
         'grammatical_features' => [
                 Wikibase::Datatype::Value::Item->new(
                         'value' => 'Q163012',
                 ),
                 Wikibase::Datatype::Value::Item->new(
                         'value' => 'Q163014',
                 ),
         ],
         'id' => 'ID',
         'representations' => [
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'en',
                         'value' => 'Representation en',
                 ),
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'cs',
                         'value' => 'Representation cs',
                 ),
         ],
         'statements' => [
                 $statement,
         ],
 );

 # Sense.
 my $sense = Wikibase::Datatype::Sense->new(
         'glosses' => [
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'en',
                         'value' => 'Glosse en',
                 ),
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'cs',
                         'value' => 'Glosse cs',
                 ),
         ],
         'id' => 'ID',
         'statements' => [
                 $statement,
         ],
 );

 my $lexeme = Wikibase::Datatype::Lexeme->new(
         'forms' => [
                 $form,
         ],
         'senses' => [
                 $sense,
         ],
         'statements' => [
                 $statement,
         ],
 );

 # Get structure.
 my $struct_hr = obj2struct($lexeme, 'http://test.wikidata.org/entity/');

 # Dump to output.
 p $struct_hr;

 # Output:
 # \ {
 #     claims   {
 #         P31   [
 #             [0] {
 #                 mainsnak   {
 #                     datatype    "wikibase-item",
 #                     datavalue   {
 #                         type    "wikibase-entityid",
 #                         value   {
 #                             entity-type   "item",
 #                             id            "Q5",
 #                             numeric-id    5
 #                         }
 #                     },
 #                     property    "P31",
 #                     snaktype    "value"
 #                 },
 #                 rank       "normal",
 #                 type       "statement"
 #             }
 #         ]
 #     },
 #     forms    [
 #         [0] {
 #             claims                {
 #                 P31   [
 #                     [0] {
 #                         mainsnak   {
 #                             datatype    "wikibase-item",
 #                             datavalue   {
 #                                 type    "wikibase-entityid",
 #                                 value   {
 #                                     entity-type   "item",
 #                                     id            "Q5",
 #                                     numeric-id    5
 #                                 }
 #                             },
 #                             property    "P31",
 #                             snaktype    "value"
 #                         },
 #                         rank       "normal",
 #                         type       "statement"
 #                     }
 #                 ]
 #             },
 #             grammaticalFeatures   [
 #                 [0] "Q163012",
 #                 [1] "Q163014"
 #             ],
 #             id                    "ID",
 #             representations       {
 #                 cs   {
 #                     language   "cs",
 #                     value      "Representation cs"
 #                 },
 #                 en   {
 #                     language   "en",
 #                     value      "Representation en"
 #                 }
 #             }
 #         }
 #     ],
 #     ns       0,
 #     senses   [
 #         [0] {
 #             claims    {
 #                 P31   [
 #                     [0] {
 #                         mainsnak   {
 #                             datatype    "wikibase-item",
 #                             datavalue   {
 #                                 type    "wikibase-entityid",
 #                                 value   {
 #                                     entity-type   "item",
 #                                     id            "Q5",
 #                                     numeric-id    5
 #                                 }
 #                             },
 #                             property    "P31",
 #                             snaktype    "value"
 #                         },
 #                         rank       "normal",
 #                         type       "statement"
 #                     }
 #                 ]
 #             },
 #             glosses   {
 #                 cs   {
 #                     language   "cs",
 #                     value      "Glosse cs"
 #                 },
 #                 en   {
 #                     language   "en",
 #                     value      "Glosse en"
 #                 }
 #             },
 #             id        "ID"
 #         }
 #     ],
 #     type     "lexeme"
 # }

=head1 EXAMPLE2

=for comment filename=struct2obj_lexeme.pl

 use strict;
 use warnings;

 use Data::Printer;
 use Unicode::UTF8 qw(decode_utf8);
 use Wikibase::Datatype::Struct::Lexeme qw(struct2obj);

 # Lexeme structure.
 my $struct_hr = {
         'claims' => {
                 'P5185' => [{
                         'mainsnak' => {
                                 'datavalue' => {
                                         'type' => 'wikibase-entityid',
                                         'value' => {
                                                 'entity-type' => 'item',
                                                 'id' => 'Q499327',
                                                 'numeric-id' => 499327,
                                         },
                                 },
                                 'datatype' => 'wikibase-item',
                                 'property' => 'P5185',
                                 'snaktype' => 'value',
                         },
                         'rank' => 'normal',
                         'references' => [{
                                 'snaks' => {
                                         'P214' => [{
                                                 'datavalue' => {
                                                         'type' => 'string',
                                                         'value' => '113230702',
                                                 },
                                                 'datatype' => 'external-id',
                                                 'property' => 'P214',
                                                 'snaktype' => 'value',
                                         }],
                                         'P248' => [{
                                                 'datavalue' => {
                                                         'type' => 'wikibase-entityid',
                                                         'value' => {
                                                                 'entity-type' => 'item',
                                                                 'id' => 'Q53919',
                                                                 'numeric-id' => 53919,
                                                         },
                                                 },
                                                 'datatype' => 'wikibase-item',
                                                 'property' => 'P248',
                                                 'snaktype' => 'value',
                                         }],
                                         'P813' => [{
                                                 'datavalue' => {
                                                         'type' => 'time',
                                                         'value' => {
                                                                 'after' => 0,
                                                                 'before' => 0,
                                                                 'calendarmodel' => 'http://test.wikidata.org/entity/Q1985727',
                                                                 'precision' => 11,
                                                                 'time' => '+2013-12-07T00:00:00Z',
                                                                 'timezone' => 0,
                                                         },
                                                 },
                                                 'datatype' => 'time',
                                                 'property' => 'P813',
                                                 'snaktype' => 'value',
                                         }],
                                 },
                                 'snaks-order' => [
                                         'P248',
                                         'P214',
                                         'P813',
                                 ],
                         }],
                         'type' => 'statement',
                 }],
         },
         'forms' => [{
                 'claims' => {
                         'P898' => [{
                                 'mainsnak' => {
                                         'datavalue' => {
                                                 'type' => 'string',
                                                 'value' => decode_utf8('pɛs'),
                                         },
                                         'datatype' => 'string',
                                         'property' => 'P898',
                                         'snaktype' => 'value',
                                 },
                                 'rank' => 'normal',
                                 'type' => 'statement',
                         }],
                 },
                 'grammaticalFeatures' => [
                         'Q110786',
                         'Q131105',
                 ],
                 'id' => 'L469-F1',
                 'representations' => {
                         'cs' => {
                                 'language' => 'cs',
                                 'value' => 'pes',
                         },
                 },
         }],
         'id' => 'L469',
         'language' => 'Q9056',
         'lastrevid' => 1428556087,
         'lemmas' => {
                 'cs' => {
                         'language' => 'cs',
                         'value' => 'pes',
                 },
         },
         'lexicalCategory' => 'Q1084',
         'modified' => '2022-06-24T12:42:10Z',
         'ns' => 146,
         'pageid' => 54393954,
         'senses' => [{
                 'claims' => {
                         'P18' => [{
                                 'mainsnak' => {
                                         'datavalue' => {
                                                 'type' => 'string',
                                                 'value' => 'Canadian Inuit Dog.jpg',
                                         },
                                         'datatype' => 'commonsMedia',
                                         'property' => 'P18',
                                         'snaktype' => 'value',
                                 },
                                 'rank' => 'normal',
                                 'type' => 'statement',
                         }],
                         'P5137' => [{
                                 'mainsnak' => {
                                         'datavalue' => {
                                                 'type' => 'wikibase-entityid',
                                                 'value' => {
                                                         'entity-type' => 'item',
                                                         'id' => 'Q144',
                                                         'numeric-id' => 144,
                                                 },
                                         },
                                         'datatype' => 'wikibase-item',
                                         'property' => 'P5137',
                                         'snaktype' => 'value',
                                 },
                                 'rank' => 'normal',
                                 'type' => 'statement',
                         }],
                 },
                 'glosses' => {
                         'cs' => {
                                 'language' => 'cs',
                                 'value' => decode_utf8('psovitá šelma chovaná jako domácí zvíře'),
                         },
                         'en' => {
                                 'language' => 'en',
                                 'value' => 'domesticated mammal related to the wolf',
                         },
                 },
                 'id' => 'L469-S1',
         }],
         'title' => 'Lexeme:L469',
         'type' => 'lexeme',
  };

 # Get object.
 my $obj = struct2obj($struct_hr);

 # Dump object.
 p $obj;

 # Output:
 # Wikibase::Datatype::Lexeme  {
 #     parents: Mo::Object
 #     public methods (5):
 #         BUILD
 #         Error::Pure:
 #             err
 #         Mo::utils:
 #             check_array_object, check_number
 #         Wikibase::Datatype::Utils:
 #             check_entity
 #     private methods (0)
 #     internals: {
 #         forms              [
 #             [0] Wikibase::Datatype::Form
 #         ],
 #         id                 "L469",
 #         language           "Q9056",
 #         lastrevid          1428556087,
 #         lemmas             [
 #             [0] Wikibase::Datatype::Value::Monolingual
 #         ],
 #         lexical_category   "Q1084",
 #         modified           "2022-06-24T12:42:10Z" (dualvar: 2022),
 #         ns                 146,
 #         page_id            54393954,
 #         senses             [
 #             [0] Wikibase::Datatype::Sense
 #         ],
 #         statements         [
 #             [0] Wikibase::Datatype::Statement
 #         ],
 #         title              "Lexeme:L469"
 #     }
 # }

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>,
L<Wikibase::Datatype::Form>,
L<Wikibase::Datatype::Lexeme>,
L<Wikibase::Datatype::Struct::Form>,
L<Wikibase::Datatype::Struct::Language>,
L<Wikibase::Datatype::Struct::Sense>,
L<Wikibase::Datatype::Struct::Statement>,
L<Wikibase::Datatype::Value::Item>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype::Form>

Wikibase form datatype.

=item L<Wikibase::Datatype::Sense>

Wikibase sense datatype.

=item L<Wikibase::Datatype::Struct>

Wikibase structure serialization.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Wikibase-Datatype-Struct>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2020-2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.13

=cut
