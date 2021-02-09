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

our $VERSION = 0.08;

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

	# Last revision id.
	if (defined $obj->lastrevid) {
		$struct_hr->{'lastrevid'} = $obj->lastrevid;
	}

	# Language.
	if (defined $obj->language) {
		$struct_hr->{'language'} = $obj->language->value;
	}

	# Lemmas.
	foreach my $lemma (@{$obj->lemmas}) {
		$struct_hr->{'lemmas'}->{$lemma->language}
			= Wikibase::Datatype::Struct::Language::obj2struct($lemma);
	}

	# Lexical category.
	if (defined $obj->lexical_category) {
		$struct_hr->{'lexicalCategory'} = $obj->lexical_category->value;
	}

	# Modified date.
	if (defined $obj->modified) {
		$struct_hr->{'modified'} = $obj->modified;
	}

	# Namespace.
	if (defined $obj->ns) {
		$struct_hr->{'ns'} = $obj->ns;
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

	# Grammatical features.
	my $gm_ar = [];
	foreach my $gm (@{$struct_hr->{'grammaticalFeatures'}}) {
		push @{$gm_ar}, Wikibase::Datatype::Value::Item->new(
			'value' => $gm,
		);
	}

	# Representations.
	my $representations_ar;
	foreach my $lang (keys %{$struct_hr->{'representations'}}) {
		push @{$representations_ar}, Wikibase::Datatype::Struct::Language::struct2obj(
			$struct_hr->{'representations'}->{$lang});
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
		'grammatical_features' => $gm_ar,
		'id' => $struct_hr->{'id'},
		'representations' => $representations_ar,
		'statements' => $statements_ar,
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

 use strict;
 use warnings;

 use Data::Printer;
 use Wikibase::Datatype::Struct::Lexeme qw(struct2obj);

 # Lexeme structure.
 my $struct_hr = {
         'grammaticalFeatures' => [
                 'Q163012',
                 'Q163014',
         ],
         'representations' => {
                 'cs' => {
                         'language' => 'cs',
                         'value' => 'Representation cs',
                 },
                 'en' => {
                         'language' => 'en',
                         'value' => 'Representation en',
                 },
         },
         'claims' => {
                 'P31' => [{
                         'mainsnak' => {
                                 'datatype' => 'wikibase-item',
                                 'datavalue' => {
                                         'type' => 'wikibase-entityid',
                                         'value' => {
                                                 'entity-type' => 'item',
                                                 'id' => 'Q5',
                                                 'numeric-id' => 5,
                                         },
                                 },
                                 'property' => 'P31',
                                 'snaktype' => 'value',
                         },
                         'rank' => 'normal',
                         'type' => 'statement',
                 }],
         },
         'type' => 'lexeme',
 };

 # Get object.
 my $obj = struct2obj($struct_hr);

 # Dump object.
 p $obj;

 # Output:
 # Wikibase::Datatype::Lexeme  {
 #     Parents       Mo::Object
 #     public methods (8) : BUILD, can (UNIVERSAL), DOES (UNIVERSAL), err (Error::Pure), check_array_object (Mo::utils), check_entity (Wikibase::Datatype::Utils), isa (UNIVERSAL), VERSION (UNIVERSAL)
 #     private methods (1) : __ANON__ (Mo::is)
 #     internals: {
 #         grammatical_features   [
 #             [0] Wikibase::Datatype::Value::Item,
 #             [1] Wikibase::Datatype::Value::Item
 #         ],
 #         id                     undef,
 #         representations        [
 #             [0] Wikibase::Datatype::Value::Monolingual,
 #             [1] Wikibase::Datatype::Value::Monolingual
 #         ],
 #         statements             [
 #             [0] Wikibase::Datatype::Statement
 #         ]
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

© Michal Josef Špaček 2020-2021

BSD 2-Clause License

=head1 VERSION

0.08

=cut
