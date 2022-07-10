package Wikibase::Datatype::Struct::Property;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Wikibase::Datatype::Property;
use Wikibase::Datatype::Struct::Language;
use Wikibase::Datatype::Struct::Statement;
use Wikibase::Datatype::Struct::Value::Monolingual;

Readonly::Array our @EXPORT_OK => qw(obj2struct struct2obj);

our $VERSION = 0.09;

sub obj2struct {
	my ($obj, $base_uri) = @_;

	if (! defined $obj) {
		err "Object doesn't exist.";
	}
	if (! $obj->isa('Wikibase::Datatype::Property')) {
		err "Object isn't 'Wikibase::Datatype::Property'.";
	}
	if (! defined $base_uri) {
		err 'Base URI is required.';
	}

	my $struct_hr = {
		'type' => 'property',
	};

	# Aliases.
	foreach my $alias (@{$obj->aliases}) {
		if (! exists $struct_hr->{'aliases'}->{$alias->language}) {
			$struct_hr->{'aliases'}->{$alias->language} = [];
		}
		push @{$struct_hr->{'aliases'}->{$alias->language}},
			Wikibase::Datatype::Struct::Language::obj2struct($alias);
	}

	# Claims.
	foreach my $statement (@{$obj->statements}) {
		$struct_hr->{'claims'}->{$statement->snak->property} //= [];
		push @{$struct_hr->{'claims'}->{$statement->snak->property}},
			Wikibase::Datatype::Struct::Statement::obj2struct($statement, $base_uri);
	}

	# Datatype.
	$struct_hr->{'datatype'} = $obj->datatype;

	# Descriptions.
	foreach my $desc (@{$obj->descriptions}) {
		$struct_hr->{'descriptions'}->{$desc->language}
			= Wikibase::Datatype::Struct::Language::obj2struct($desc);
	}

	# Id.
	if (defined $obj->id) {
		$struct_hr->{'id'} = $obj->id;
	}

	# Labels.
	foreach my $label (@{$obj->labels}) {
		$struct_hr->{'labels'}->{$label->language}
			= Wikibase::Datatype::Struct::Language::obj2struct($label);
	}
	
	# Last revision id.
	if (defined $obj->lastrevid) {
		$struct_hr->{'lastrevid'} = $obj->lastrevid;
	}

	# Modified date.
	if (defined $obj->modified) {
		$struct_hr->{'modified'} = $obj->modified;
	}

	# Namespace.
	if (defined $obj->ns) {
		$struct_hr->{'ns'} = $obj->ns;
	}

	# Page ID.
	if (defined $obj->page_id) {
		$struct_hr->{'pageid'} = $obj->page_id;
	}

	# Title.
	if (defined $obj->title) {
		$struct_hr->{'title'} = $obj->title;
	}

	return $struct_hr;
}

sub struct2obj {
	my $struct_hr = shift;

	if (! exists $struct_hr->{'type'} || $struct_hr->{'type'} ne 'property') {
		err "Structure isn't for 'property' type.";
	}

	# Aliases.
	my $aliases_ar = [];
	foreach my $lang (keys %{$struct_hr->{'aliases'}}) {
		foreach my $alias_hr (@{$struct_hr->{'aliases'}->{$lang}}) {
			push @{$aliases_ar}, Wikibase::Datatype::Struct::Language::struct2obj(
				$alias_hr,
			);
		}
	}

	# Descriptions.
	my $descriptions_ar = [];
	foreach my $lang (keys %{$struct_hr->{'descriptions'}}) {
		push @{$descriptions_ar}, Wikibase::Datatype::Struct::Language::struct2obj(
			$struct_hr->{'descriptions'}->{$lang},
		);
	}

	# Labels.
	my $labels_ar = [];
	foreach my $lang (keys %{$struct_hr->{'labels'}}) {
		push @{$labels_ar}, Wikibase::Datatype::Struct::Language::struct2obj(
			$struct_hr->{'labels'}->{$lang},
		);
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

	my $obj = Wikibase::Datatype::Property->new(
		'aliases' => $aliases_ar,
		'datatype' => $struct_hr->{'datatype'},
		'descriptions' => $descriptions_ar,
		defined $struct_hr->{'id'} ? ('id' => $struct_hr->{'id'}) : (),
		'labels' => $labels_ar,
		defined $struct_hr->{'lastrevid'} ? ('lastrevid' => $struct_hr->{'lastrevid'}) : (),
		defined $struct_hr->{'modified'} ? ('modified' => $struct_hr->{'modified'}) : (),
		defined $struct_hr->{'ns'} ? ('ns' => $struct_hr->{'ns'}) : (),
		defined $struct_hr->{'pageid'} ? ('page_id' => $struct_hr->{'pageid'}) : (),
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

Wikibase::Datatype::Struct::Property - Wikibase property structure serialization.

=head1 SYNOPSIS

 use Wikibase::Datatype::Struct::Property qw(obj2struct struct2obj);

 my $struct_hr = obj2struct($obj, $base_uri);
 my $obj = struct2obj($struct_hr);

=head1 DESCRIPTION

This conversion is between objects defined in Wikibase::Datatype and structures
serialized via JSON to MediaWiki.

=head1 SUBROUTINES

=head2 C<obj2struct>

 my $struct_hr = obj2struct($obj, $base_uri);

Convert Wikibase::Datatype::Property instance to structure.
C<$base_uri> is base URI of Wikibase system (e.g. http://test.wikidata.org/entity/).

Returns reference to hash with structure.

=head2 C<struct2obj>

 my $obj = struct2obj($struct_hr);

Convert structure of property to object.

Returns Wikibase::Datatype::Property instance.

=head1 ERRORS

 obj2struct():
         Base URI is required.
         Object doesn't exist.
         Object isn't 'Wikibase::Datatype::Property'.

 struct2obj():
         Structure isn't for 'property' type.

=head1 EXAMPLE1

 use strict;
 use warnings;

 use Data::Printer;
 use Unicode::UTF8 qw(decode_utf8);
 use Wikibase::Datatype::Property;
 use Wikibase::Datatype::Reference;
 use Wikibase::Datatype::Sitelink;
 use Wikibase::Datatype::Snak;
 use Wikibase::Datatype::Statement;
 use Wikibase::Datatype::Struct::Property qw(obj2struct);
 use Wikibase::Datatype::Value::Item;
 use Wikibase::Datatype::Value::Monolingual;
 use Wikibase::Datatype::Value::String;
 use Wikibase::Datatype::Value::Time;

 # Statement.
 my $statement1 = Wikibase::Datatype::Statement->new(
         # instance of (P31) Wikidata property (Q18616576)
         'snak' => Wikibase::Datatype::Snak->new(
                 'datatype' => 'wikibase-item',
                 'datavalue' => Wikibase::Datatype::Value::Item->new(
                         'value' => 'Q18616576',
                 ),
                 'property' => 'P31',
         ),
 );

 # Main property.
 my $obj = Wikibase::Datatype::Property->new(
         'aliases' => [
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'cs',
                         'value' => 'je',
                 ),
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'en',
                         'value' => 'is a',
                 ),
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'en',
                         'value' => 'is an',
                 ),
         ],
         'datatype' => 'wikibase-item',
         'descriptions' => [
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'cs',
                         'value' => decode_utf8('tato položka je jedna konkrétní věc (exemplář, '.
                                 'příklad) patřící do této třídy, kategorie nebo skupiny předmětů'),
                 ),
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'en',
                         'value' => 'that class of which this subject is a particular example and member',
                 ),
         ],
         'id' => 'P31',
         'labels' => [
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'cs',
                         'value' => decode_utf8('instance (čeho)'),
                 ),
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'en',
                         'value' => 'instance of',
                 ),
         ],
         'page_id' => 3918489,
         'statements' => [
                 $statement1,
         ],
         'title' => 'Property:P31',
 );

 # Get structure.
 my $struct_hr = obj2struct($obj, 'http://test.wikidata.org/entity/');

 # Dump to output.
 p $struct_hr;

 # Output:
 # {
 #     aliases        {
 #         cs   [
 #             [0] {
 #                     language   "cs",
 #                     value      "je"
 #                 }
 #         ],
 #         en   [
 #             [0] {
 #                     language   "en",
 #                     value      "is a"
 #                 },
 #             [1] {
 #                     language   "en",
 #                     value      "is an"
 #                 }
 #         ]
 #     },
 #     claims         {
 #         P31   [
 #             [0] {
 #                     mainsnak   {
 #                         datatype    "wikibase-item",
 #                         datavalue   {
 #                             type    "wikibase-entityid",
 #                             value   {
 #                                 entity-type   "item",
 #                                 id            "Q18616576",
 #                                 numeric-id    18616576
 #                             }
 #                         },
 #                         property    "P31",
 #                         snaktype    "value"
 #                     },
 #                     rank       "normal",
 #                     type       "statement"
 #                 }
 #         ]
 #     },
 #     datatype       "wikibase-item",
 #     descriptions   {
 #         cs   {
 #             language   "cs",
 #             value      "tato položka je jedna konkrétní věc (exemplář, příklad) patřící do této třídy, kategorie nebo skupiny předmětů"
 #         },
 #         en   {
 #             language   "en",
 #             value      "that class of which this subject is a particular example and member"
 #         }
 #     },
 #     id             "P31",
 #     labels         {
 #         cs   {
 #             language   "cs",
 #             value      "instance (čeho)"
 #         },
 #         en   {
 #             language   "en",
 #             value      "instance of"
 #         }
 #     },
 #     ns             120,
 #     pageid         3918489,
 #     title          "Property:P31",
 #     type           "property"
 # }

=head1 EXAMPLE2

 use strict;
 use warnings;

 use Data::Printer;
 use Unicode::UTF8 qw(decode_utf8);
 use Wikibase::Datatype::Struct::Property qw(struct2obj);

 # Item structure.
 my $struct_hr = {
         'aliases' => {
                 'cs' => [{
                         'language' => 'cs',
                         'value' => 'je',
                 }],
                 'en' => [{
                         'language' => 'en',
                         'value' => 'is a',
                 }, {
                         'language' => 'en',
                         'value' => 'is an',
                 }],
         },
         'claims' => {
                 'P31' => [{
                         'mainsnak' => {
                                 'datatype' => 'wikibase-item',
                                 'datavalue' => {
                                         'type' => 'wikibase-entityid',
                                         'value' => {
                                                 'entity-type' => 'item',
                                                 'id' => 'Q18616576',
                                                 'numeric-id' => 18616576,
                                         },
                                 },
                                 'property' => 'P31',
                                 'snaktype' => 'value',
                         },
                         'rank' => 'normal',
                         'type' => 'statement',
                 }],
         },
         'datatype' => 'wikibase-item',
         'descriptions' => {
                 'cs' => {
                         'language' => 'cs',
                         'value' => decode_utf8('tato položka je jedna konkrétní věc (exemplář, příklad) patřící do této třídy, kategorie nebo skupiny předmětů'),
                 },
                 'en' => {
                         'language' => 'en',
                         'value' => 'that class of which this subject is a particular example and member',
                 },
         },
         'id' => 'P31',
         'labels' => {
                 'cs' => {
                         'language' => 'cs',
                         'value' => decode_utf8('instance (čeho)'),
                 },
                 'en' => {
                         'language' => 'en',
                         'value' => 'instance of',
                 },
         },
         'ns' => 120,
         'pageid' => 3918489,
         'title' => 'Property:P31',
         'type' => 'property',
 };

 # Get object.
 my $obj = struct2obj($struct_hr);

 # Print out.
 p $obj;

 # Output:
 # Wikibase::Datatype::Property  {
 #     parents: Mo::Object
 #     public methods (8):
 #         BUILD
 #         Error::Pure:
 #             err
 #         List::Util:
 #             none
 #         Mo::utils:
 #             check_array_object, check_number, check_number_of_items, check_required
 #         Readonly:
 #             Readonly
 #     private methods (0)
 #     internals: {
 #         aliases        [
 #             [0] Wikibase::Datatype::Value::Monolingual,
 #             [1] Wikibase::Datatype::Value::Monolingual,
 #             [2] Wikibase::Datatype::Value::Monolingual
 #         ],
 #         datatype       "wikibase-item",
 #         descriptions   [
 #             [0] Wikibase::Datatype::Value::Monolingual,
 #             [1] Wikibase::Datatype::Value::Monolingual
 #         ],
 #         id             "P31",
 #         labels         [
 #             [0] Wikibase::Datatype::Value::Monolingual,
 #             [1] Wikibase::Datatype::Value::Monolingual
 #         ],
 #         ns             120,
 #         page_id        3918489,
 #         statements     [
 #             [0] Wikibase::Datatype::Statement
 #         ],
 #         title          "Property:P31"
 #     }
 # }

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>,
L<Wikibase::Datatype::Item>,
L<Wikibase::Datatype::Reference>,
L<Wikibase::Datatype::Struct::Language>,
L<Wikibase::Datatype::Struct::Statement>,
L<Wikibase::Datatype::Struct::Value::Monolingual>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype::Struct>

Wikibase structure serialization.

=item L<Wikibase::Datatype::Item>

Wikibase item datatype.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Wikibase-Datatype-Struct>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2020-2022 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.09

=cut
