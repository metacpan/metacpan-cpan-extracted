package Wikibase::Datatype::Struct::MediainfoSnak;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Wikibase::Datatype::MediainfoSnak;
use Wikibase::Datatype::Struct::Value;

Readonly::Array our @EXPORT_OK => qw(obj2struct struct2obj);

our $VERSION = 0.14;

sub obj2struct {
	my ($obj, $base_uri) = @_;

	if (! defined $obj) {
		err "Object doesn't exist.";
	}
	if (! $obj->isa('Wikibase::Datatype::MediainfoSnak')) {
		err "Object isn't 'Wikibase::Datatype::MediainfoSnak'.";
	}
	if (! defined $base_uri) {
		err 'Base URI is required.';
	}

	my $struct_hr = {
		defined $obj->datavalue
			? ('datavalue' => Wikibase::Datatype::Struct::Value::obj2struct($obj->datavalue, $base_uri))
			: (),
		'property' => $obj->property,
		'snaktype' => $obj->snaktype,
	};

	return $struct_hr;
}

sub struct2obj {
	my $struct_hr = shift;

	# Data value isn't required for snaktype 'novalue'.
	my $datavalue;
	if (exists $struct_hr->{'datavalue'}) {
		$datavalue = Wikibase::Datatype::Struct::Value::struct2obj($struct_hr->{'datavalue'});
	}

	my $obj = Wikibase::Datatype::MediainfoSnak->new(
		($struct_hr->{'snaktype'} eq 'value') ? (
			'datavalue' => $datavalue,
		) : (),
		'property' => $struct_hr->{'property'},
		'snaktype' => $struct_hr->{'snaktype'},
	);

	return $obj;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Struct::MediainfoSnak - Wikibase mediainfo snak structure serialization.

=head1 SYNOPSIS

 use Wikibase::Datatype::Struct::MediainfoSnak qw(obj2struct struct2obj);

 my $struct_hr = obj2struct($obj, $base_uri);
 my $obj = struct2obj($struct_hr);

=head1 DESCRIPTION

This conversion is between objects defined in Wikibase::Datatype and structures
serialized via JSON to MediaWiki.

=head1 SUBROUTINES

=head2 C<obj2struct>

 my $struct_hr = obj2struct($obj, $base_uri);

Convert Wikibase::Datatype::MediainfoSnak instance to structure.
C<$base_uri> is base URI of Wikibase system (e.g. http://test.wikidata.org/entity/).

Returns reference to hash with structure.

=head2 C<struct2obj>

 my $obj = struct2obj($struct_hr);

Convert structure of mediainfo snak to object.

Returns Wikibase::Datatype::MediainfoSnak instance.

=head1 ERRORS

 obj2struct():
         Base URI is required.
         Object doesn't exist.
         Object isn't 'Wikibase::Datatype::MediainfoSnak'.

=head1 EXAMPLE1

=for comment filename=obj2struct_mediainfo_snak.pl

 use strict;
 use warnings;

 use Data::Printer;
 use Wikibase::Datatype::MediainfoSnak;
 use Wikibase::Datatype::Struct::MediainfoSnak qw(obj2struct);
 use Wikibase::Datatype::Value::Item;

 # Object.
 # instance of (P31) human (Q5)
 my $obj = Wikibase::Datatype::MediainfoSnak->new(
          'datavalue' => Wikibase::Datatype::Value::Item->new(
                  'value' => 'Q5',
          ),
          'property' => 'P31',
 );

 # Get structure.
 my $struct_hr = obj2struct($obj, 'http://test.wikidata.org/entity/');

 # Dump to output.
 p $struct_hr;

 # Output:
 # \ {
 #     datavalue   {
 #         type    "wikibase-entityid",
 #         value   {
 #             entity-type   "item",
 #             id            "Q5",
 #             numeric-id    5
 #         }
 #     },
 #     property    "P31",
 #     snaktype    "value"
 # }

=head1 EXAMPLE2

=for comment filename=struct2obj_mediainfo_snak.pl

 use strict;
 use warnings;

 use Wikibase::Datatype::Struct::MediainfoSnak qw(struct2obj);

 # Item structure.
 my $struct_hr = {
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
 };

 # Get object.
 my $obj = struct2obj($struct_hr);

 # Get value.
 my $datavalue = $obj->datavalue->value;

 # Get property.
 my $property = $obj->property;

 # Get snak type.
 my $snaktype = $obj->snaktype;

 # Print out.
 print "Property: $property\n";
 print "Value: $datavalue\n";
 print "Snak type: $snaktype\n";

 # Output:
 # Property: P31
 # Value: Q5
 # Snak type: value

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>,
L<Wikibase::Datatype::MediainfoSnak>,
L<Wikibase::Datatype::Struct::Value>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype::Struct>

Wikibase structure serialization.

=item L<Wikibase::Datatype::Struct::Snak>

Wikibase snak structure serialization.

=item L<Wikibase::Datatype::Snak>

Wikibase snak datatype.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Wikibase-Datatype-Struct>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2020-2025 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.14

=cut
