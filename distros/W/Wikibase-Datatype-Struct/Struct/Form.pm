package Wikibase::Datatype::Struct::Form;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Wikibase::Datatype::Form;
use Wikibase::Datatype::Struct::Language;
use Wikibase::Datatype::Struct::Statement;
use Wikibase::Datatype::Value::Item;

Readonly::Array our @EXPORT_OK => qw(obj2struct struct2obj);

our $VERSION = 0.08;

sub obj2struct {
	my ($obj, $base_uri) = @_;

	if (! defined $obj) {
		err "Object doesn't exist.";
	}
	if (! $obj->isa('Wikibase::Datatype::Form')) {
		err "Object isn't 'Wikibase::Datatype::Form'.";
	}
	if (! defined $base_uri) {
		err 'Base URI is required.';
	}

	my $struct_hr = {
		'id' => $obj->id,
	};

	# Grammatical features.
	foreach my $gf (@{$obj->grammatical_features}) {
		push @{$struct_hr->{'grammaticalFeatures'}}, $gf->value;
	}

	# Representations.
	foreach my $rep (@{$obj->representations}) {
		$struct_hr->{'representations'}->{$rep->language}
			= Wikibase::Datatype::Struct::Language::obj2struct($rep);
	}

	# Statements.
	foreach my $statement (@{$obj->statements}) {
		$struct_hr->{'claims'}->{$statement->snak->property} //= [];
		push @{$struct_hr->{'claims'}->{$statement->snak->property}},
			Wikibase::Datatype::Struct::Statement::obj2struct($statement, $base_uri);
	}

	return $struct_hr;
}

sub struct2obj {
	my $struct_hr = shift;

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

	my $obj = Wikibase::Datatype::Form->new(
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

Wikibase::Datatype::Struct::Form - Wikibase form structure serialization.

=head1 SYNOPSIS

 use Wikibase::Datatype::Struct::Form qw(obj2struct struct2obj);

 my $struct_hr = obj2struct($obj, $base_uri);
 my $obj = struct2obj($struct_hr);

=head1 DESCRIPTION

This conversion is between objects defined in Wikibase::Datatype and structures
serialized via JSON to MediaWiki.

=head1 SUBROUTINES

=head2 C<obj2struct>

 my $struct_hr = obj2struct($obj, $base_uri);

Convert Wikibase::Datatype::Form instance to structure.
C<$base_uri> is base URI of Wikibase system (e.g. http://test.wikidata.org/entity/).

Returns reference to hash with structure.

=head2 C<struct2obj>

 my $obj = struct2obj($struct_hr);

Convert structure of form to object.

Returns Wikibase::Datatype::Form instance.

=head1 ERRORS

 obj2struct():
         Base URI is required.
         Object doesn't exist.
         Object isn't 'Wikibase::Datatype::Form'.

=head1 EXAMPLE1

 use strict;
 use warnings;

 use Data::Printer;
 use Wikibase::Datatype::Form;
 use Wikibase::Datatype::Statement;
 use Wikibase::Datatype::Struct::Form qw(obj2struct);
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

 # Object.
 my $obj = Wikibase::Datatype::Form->new(
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

 # Get structure.
 my $struct_hr = obj2struct($obj, 'http://test.wikidata.org/entity/');

 # Dump to output.
 p $struct_hr;

 # Output:
 # \ {
 #     claims                {
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
 #     grammaticalFeatures   [
 #         [0] "Q163012",
 #         [1] "Q163014"
 #     ],
 #     id                    "ID",
 #     represenations        {
 #         cs   {
 #             language   "cs",
 #             value      "Representation cs"
 #         },
 #         en   {
 #             language   "en",
 #             value      "Representation en"
 #         }
 #     }
 # }

=head1 EXAMPLE2

 use strict;
 use warnings;

 use Data::Printer;
 use Wikibase::Datatype::Struct::Form qw(struct2obj);

 # Item structure.
 my $struct_hr = {
         'grammaticalFeatures' => [
                 'Q163012',
                 'Q163014',
         ],
         'id' => 'ID',
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
 };

 # Get object.
 my $obj = struct2obj($struct_hr);

 # Dump object.
 p $obj;

 # Output:
 # Wikibase::Datatype::Form  {
 #     Parents       Mo::Object
 #     public methods (6) : BUILD, can (UNIVERSAL), DOES (UNIVERSAL), check_array_object (Mo::utils), isa (UNIVERSAL), VERSION (UNIVERSAL)
 #     private methods (1) : __ANON__ (Mo::is)
 #     internals: {
 #         grammatical_features   [
 #             [0] Wikibase::Datatype::Value::Item,
 #             [1] Wikibase::Datatype::Value::Item
 #         ],
 #         id                     "ID",
 #         represenations         undef,
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
L<Wikibase::Datatype::Struct::Language>,
L<Wikibase::Datatype::Struct::Statement>,
L<Wikibase::Datatype::Value::Item>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype::Struct>

Wikibase structure serialization.

=item L<Wikibase::Datatype::Form>

Wikibase form datatype.

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
