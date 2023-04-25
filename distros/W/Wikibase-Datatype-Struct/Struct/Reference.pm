package Wikibase::Datatype::Struct::Reference;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Wikibase::Datatype::Reference;
use Wikibase::Datatype::Struct::Utils qw(obj_array_ref2struct struct2snaks_array_ref);

Readonly::Array our @EXPORT_OK => qw(obj2struct struct2obj);

our $VERSION = 0.11;

sub obj2struct {
	my ($obj, $base_uri) = @_;

	if (! defined $obj) {
		err "Object doesn't exist.";
	}
	if (! $obj->isa('Wikibase::Datatype::Reference')) {
		err "Object isn't 'Wikibase::Datatype::Reference'.";
	}
	if (! defined $base_uri) {
		err 'Base URI is required.';
	}

	my $struct_hr = obj_array_ref2struct($obj->snaks, 'snaks', $base_uri);

	return $struct_hr;
}

sub struct2obj {
	my $struct_hr = shift;

	my $obj = Wikibase::Datatype::Reference->new(
		'snaks' => struct2snaks_array_ref($struct_hr, 'snaks'),
	);

	return $obj;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Struct::Reference - Wikibase reference structure serialization.

=head1 SYNOPSIS

 use Wikibase::Datatype::Struct::Reference qw(obj2struct struct2obj);

 my $struct_hr = obj2struct($obj, $base_uri);
 my $obj = struct2obj($struct_hr);

=head1 DESCRIPTION

This conversion is between objects defined in Wikibase::Datatype and structures
serialized via JSON to MediaWiki.

=head1 SUBROUTINES

=head2 C<obj2struct>

 my $struct_hr = obj2struct($obj, $base_uri);

Convert Wikibase::Datatype::Reference instance to structure.
C<$base_uri> is base URI of Wikibase system (e.g. http://test.wikidata.org/entity/).

Returns reference to hash with structure.

=head2 C<struct2obj>

 my $obj = struct2obj($struct_hr);

Convert structure of reference to object.

Returns Wikibase::Datatype::Reference instance.

=head1 ERRORS

 obj2struct():
         Base URI is required.
         Object doesn't exist.
         Object isn't 'Wikibase::Datatype::Reference'.

=head1 EXAMPLE1

=for comment filename=obj2struct_reference.pl

 use strict;
 use warnings;

 use Data::Printer;
 use Wikibase::Datatype::Reference;
 use Wikibase::Datatype::Snak;
 use Wikibase::Datatype::Struct::Reference qw(obj2struct);
 use Wikibase::Datatype::Value::Item;
 use Wikibase::Datatype::Value::String;
 use Wikibase::Datatype::Value::Time;

 # Object.
 # instance of (P31) human (Q5)
 my $obj = Wikibase::Datatype::Reference->new(
          'snaks' => [
                  # stated in (P248) Virtual International Authority File (Q53919)
                  Wikibase::Datatype::Snak->new(
                           'datatype' => 'wikibase-item',
                           'datavalue' => Wikibase::Datatype::Value::Item->new(
                                   'value' => 'Q53919',
                           ),
                           'property' => 'P248',
                  ),

                  # VIAF ID (P214) 113230702
                  Wikibase::Datatype::Snak->new(
                           'datatype' => 'external-id',
                           'datavalue' => Wikibase::Datatype::Value::String->new(
                                   'value' => '113230702',
                           ),
                           'property' => 'P214',
                  ),

                  # retrieved (P813) 7 December 2013
                  Wikibase::Datatype::Snak->new(
                           'datatype' => 'time',
                           'datavalue' => Wikibase::Datatype::Value::Time->new(
                                   'value' => '+2013-12-07T00:00:00Z',
                           ),
                           'property' => 'P813',
                  ),
          ],
 );

 # Get structure.
 my $struct_hr = obj2struct($obj, 'http://test.wikidata.org/entity/');

 # Dump to output.
 p $struct_hr;

 # Output:
 # \ {
 #     snaks         {
 #         P214   [
 #             [0] {
 #                 datatype    "external-id",
 #                 datavalue   {
 #                     type    "string",
 #                     value   113230702
 #                 },
 #                 property    "P214",
 #                 snaktype    "value"
 #             }
 #         ],
 #         P248   [
 #             [0] {
 #                 datatype    "wikibase-item",
 #                 datavalue   {
 #                     type    "wikibase-entityid",
 #                     value   {
 #                         entity-type   "item",
 #                         id            "Q53919",
 #                         numeric-id    53919
 #                     }
 #                 },
 #                 property    "P248",
 #                 snaktype    "value"
 #             }
 #         ],
 #         P813   [
 #             [0] {
 #                 datatype    "time",
 #                 datavalue   {
 #                     type    "time",
 #                     value   {
 #                         after           0,
 #                         before          0,
 #                         calendarmodel   "http://test.wikidata.org/entity/Q1985727",
 #                         precision       11,
 #                         time            "+2013-12-07T00:00:00Z",
 #                         timezone        0
 #                     }
 #                 },
 #                 property    "P813",
 #                 snaktype    "value"
 #             }
 #         ]
 #     },
 #     snaks-order   [
 #         [0] "P248",
 #         [1] "P214",
 #         [2] "P813"
 #     ]
 # }

=head1 EXAMPLE2

=for comment filename=struct2obj_reference.pl

 use strict;
 use warnings;

 use Wikibase::Datatype::Struct::Reference qw(struct2obj);

 # Item structure.
 my $struct_hr = {
         'snaks' => {
                 'P214' => [{
                         'datatype' => 'external-id',
                         'datavalue' => {
                                 'type' => 'string',
                                 'value' => '113230702',
                         },
                         'property' => 'P214',
                         'snaktype' => 'value',
                 }],
                 'P248' => [{
                         'datatype' => 'wikibase-item',
                         'datavalue' => {
                                 'type' => 'wikibase-entityid',
                                 'value' => {
                                         'entity-type' => 'item',
                                         'id' => 'Q53919',
                                         'numeric-id' => 53919,
                                 },
                         },
                         'property' => 'P248',
                         'snaktype' => 'value',
                 }],
                 'P813' => [{
                         'datatype' => 'time',
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
                         'property' => 'P813',
                         'snaktype' => 'value',
                 }],
         },
         'snaks-order' => [
                 'P248',
                 'P214',
                 'P813',
         ],
 };

 # Get object.
 my $obj = struct2obj($struct_hr);

 # Get value.
 my $snaks_ar = $obj->snaks;

 # Print out number of snaks.
 print "Number of snaks: ".@{$snaks_ar}."\n";

 # Output:
 # Number of snaks: 3

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>,
L<Wikibase::Datatype::Reference>,
L<Wikibase::Datatype::Struct::Utils>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype::Struct>

Wikibase structure serialization.

=item L<Wikibase::Datatype::Reference>

Wikibase reference datatype.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Wikibase-Datatype-Struct>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2020-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.11

=cut
