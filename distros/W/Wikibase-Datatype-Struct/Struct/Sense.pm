package Wikibase::Datatype::Struct::Sense;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Wikibase::Datatype::Sense;
use Wikibase::Datatype::Struct::Language;
use Wikibase::Datatype::Struct::Statement;

Readonly::Array our @EXPORT_OK => qw(obj2struct struct2obj);

our $VERSION = 0.13;

sub obj2struct {
	my ($obj, $base_uri) = @_;

	if (! defined $obj) {
		err "Object doesn't exist.";
	}
	if (! $obj->isa('Wikibase::Datatype::Sense')) {
		err "Object isn't 'Wikibase::Datatype::Sense'.";
	}
	if (! defined $base_uri) {
		err 'Base URI is required.';
	}

	my $struct_hr = {};

	if (defined $obj->id) {
		$struct_hr->{'id'} = $obj->id;
	} else {
		# Key for information, that I am creating structure.
		$struct_hr->{'add'} = '';
	}

	# Glosses.
	foreach my $glosse (@{$obj->glosses}) {
		$struct_hr->{'glosses'}->{$glosse->language}
			= Wikibase::Datatype::Struct::Language::obj2struct($glosse);
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

	# Glosses.
	my $glosses_ar;
	foreach my $lang (keys %{$struct_hr->{'glosses'}}) {
		push @{$glosses_ar}, Wikibase::Datatype::Struct::Language::struct2obj($struct_hr->{'glosses'}->{$lang});
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

	my $obj = Wikibase::Datatype::Sense->new(
		'glosses' => $glosses_ar,
		'id' => $struct_hr->{'id'},
		'statements' => $statements_ar,
	);

	return $obj;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Struct::Sense - Wikibase sense structure serialization.

=head1 SYNOPSIS

 use Wikibase::Datatype::Struct::Sense qw(obj2struct struct2obj);

 my $struct_hr = obj2struct($obj, $base_uri);
 my $obj = struct2obj($struct_hr);

=head1 DESCRIPTION

This conversion is between objects defined in Wikibase::Datatype and structures
serialized via JSON to MediaWiki.

=head1 SUBROUTINES

=head2 C<obj2struct>

 my $struct_hr = obj2struct($obj, $base_uri);

Convert Wikibase::Datatype::Sense instance to structure.
C<$base_uri> is base URI of Wikibase system (e.g. http://test.wikidata.org/entity/).

Returns reference to hash with structure.

=head2 C<struct2obj>

 my $obj = struct2obj($struct_hr);

Convert structure of sense to object.

Returns Wikibase::Datatype::Sense instance.

=head1 ERRORS

 obj2struct():
         Base URI is required.
         Object doesn't exist.
         Object isn't 'Wikibase::Datatype::Sense'.

=head1 EXAMPLE1

=for comment filename=obj2struct_sense.pl

 use strict;
 use warnings;

 use Data::Printer;
 use Wikibase::Datatype::Sense;
 use Wikibase::Datatype::Snak;
 use Wikibase::Datatype::Statement;
 use Wikibase::Datatype::Struct::Sense qw(obj2struct);
 use Wikibase::Datatype::Value::Item;
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
 my $obj = Wikibase::Datatype::Sense->new(
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

 # Get structure.
 my $struct_hr = obj2struct($obj, 'http://test.wikidata.org/entity/');

 # Dump to output.
 p $struct_hr;

 # Output:
 # \ {
 #     glosses      {
 #         cs   {
 #             language   "cs",
 #             value      "Glosse cs"
 #         },
 #         en   {
 #             language   "en",
 #             value      "Glosse en"
 #         }
 #     },
 #     id           "ID",
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
 #     }
 # }

=head1 EXAMPLE2

=for comment filename=struct2obj_sense.pl

 use strict;
 use warnings;

 use Data::Printer;
 use Wikibase::Datatype::Struct::Sense qw(struct2obj);

 # Item structure.
 my $struct_hr = {
         'glosses' => {
                 'cs' => {
                         'language' => 'cs',
                         'value' => 'Glosse cs',
                 },
                 'en' => {
                         'language' => 'en',
                         'value' => 'Glosse en',
                 },
         },
         'id' => 'ID',
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
 # Wikibase::Datatype::Sense  {
 #     Parents       Mo::Object
 #     public methods (7) : BUILD, can (UNIVERSAL), DOES (UNIVERSAL), check_array_object (Mo::utils), check_number_of_items (Mo::utils), isa (UNIVERSAL), VERSION (UNIVERSAL)
 #     private methods (1) : __ANON__ (Mo)
 #     internals: {
 #         glosses      [
 #             [0] Wikibase::Datatype::Value::Monolingual,
 #             [1] Wikibase::Datatype::Value::Monolingual
 #         ],
 #         id           "ID",
 #         statements   [
 #             [0] Wikibase::Datatype::Statement
 #         ]
 #     }
 # }

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>,
L<Wikibase::Datatype::Sense>,
L<Wikibase::Datatype::Struct::Language>,
L<Wikibase::Datatype::Struct::Statement>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype::Struct>

Wikibase structure serialization.

=item L<Wikibase::Datatype::Sense>

Wikibase sense datatype.

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
