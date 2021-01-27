package Wikibase::Datatype::Struct::Statement;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Wikibase::Datatype::Statement;
use Wikibase::Datatype::Struct::Reference;
use Wikibase::Datatype::Struct::Snak;
use Wikibase::Datatype::Struct::Utils qw(obj_array_ref2struct struct2snaks_array_ref);

Readonly::Array our @EXPORT_OK => qw(obj2struct struct2obj);

our $VERSION = 0.07;

sub obj2struct {
	my ($obj, $base_uri) = @_;

	if (! defined $obj) {
		err "Object doesn't exist.";
	}
	if (! $obj->isa('Wikibase::Datatype::Statement')) {
		err "Object isn't 'Wikibase::Datatype::Statement'.";
	}
	if (! defined $base_uri) {
		err 'Base URI is required.';
	}

	my $struct_hr = {
		defined $obj->id ? ('id' => $obj->id) : (),
		'mainsnak' => Wikibase::Datatype::Struct::Snak::obj2struct($obj->snak, $base_uri),
		@{$obj->property_snaks} ? (
			%{obj_array_ref2struct($obj->property_snaks, 'qualifiers', $base_uri)},
		) : (),
		'rank' => $obj->rank,
		@{$obj->references} ? (
			'references' => [
				map { Wikibase::Datatype::Struct::Reference::obj2struct($_, $base_uri); }
				@{$obj->references},
			],
		) : (),
		'type' => 'statement',
	};

	return $struct_hr;
}

sub struct2obj {
	my $struct_hr = shift;

	my $obj = Wikibase::Datatype::Statement->new(
		exists $struct_hr->{'id'} ? ('id' => $struct_hr->{'id'}) : (),
		'property_snaks' => struct2snaks_array_ref($struct_hr, 'qualifiers'),
		'snak' => Wikibase::Datatype::Struct::Snak::struct2obj($struct_hr->{'mainsnak'}),
		'references' => [
			map { Wikibase::Datatype::Struct::Reference::struct2obj($_) }
			@{$struct_hr->{'references'}}
		],
		'rank' => $struct_hr->{'rank'},
	);

	return $obj;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Struct::Statement - Wikibase statement structure serialization.

=head1 SYNOPSIS

 use Wikibase::Datatype::Struct::Statement qw(obj2struct struct2obj);

 my $struct_hr = obj2struct($obj, $base_uri);
 my $obj = struct2obj($struct_hr);

=head1 DESCRIPTION

This conversion is between objects defined in Wikibase::Datatype and structures
serialized via JSON to MediaWiki.

=head1 SUBROUTINES

=head2 C<obj2struct>

 my $struct_hr = obj2struct($obj, $base_uri);

Convert Wikibase::Datatype::Statement instance to structure.
C<$base_uri> is base URI of Wikibase system (e.g. http://test.wikidata.org/entity/).

Returns reference to hash with structure.

=head2 C<struct2obj>

 my $obj = struct2obj($struct_hr);

Convert structure of statement to object.

Returns Wikibase::Datatype::Statement instance.

=head1 ERRORS

 obj2struct():
         Base URI is required.
         Object doesn't exist.
         Object isn't 'Wikibase::Datatype::Statement'.

=head1 EXAMPLE1

 use strict;
 use warnings;

 use Data::Printer;
 use Wikibase::Datatype::Reference;
 use Wikibase::Datatype::Snak;
 use Wikibase::Datatype::Statement;
 use Wikibase::Datatype::Struct::Statement qw(obj2struct);
 use Wikibase::Datatype::Value::Item;
 use Wikibase::Datatype::Value::String;
 use Wikibase::Datatype::Value::Time;

 # Object.
 my $obj = Wikibase::Datatype::Statement->new(
         'id' => 'Q123$00C04D2A-49AF-40C2-9930-C551916887E8',

         # instance of (P31) human (Q5)
         'snak' => Wikibase::Datatype::Snak->new(
                  'datatype' => 'wikibase-item',
                  'datavalue' => Wikibase::Datatype::Value::Item->new(
                          'value' => 'Q5',
                  ),
                  'property' => 'P31',
         ),
         'property_snaks' => [
                 # of (P642) alien (Q474741)
                 Wikibase::Datatype::Snak->new(
                          'datatype' => 'wikibase-item',
                          'datavalue' => Wikibase::Datatype::Value::Item->new(
                                  'value' => 'Q474741',
                          ),
                          'property' => 'P642',
                 ),
         ],
         'references' => [
                  Wikibase::Datatype::Reference->new(
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
                  ),
         ],
 );

 # Get structure.
 my $struct_hr = obj2struct($obj, 'http://test.wikidata.org/entity/');

 # Dump to output.
 p $struct_hr;

 # Output:
 # \ {
 #     id                 "Q123$00C04D2A-49AF-40C2-9930-C551916887E8",
 #     mainsnak           {
 #         datatype    "wikibase-item",
 #         datavalue   {
 #             type    "wikibase-entityid",
 #             value   {
 #                 entity-type   "item",
 #                 id            "Q5",
 #                 numeric-id    5
 #             }
 #         },
 #         property    "P31",
 #         snaktype    "value"
 #     },
 #     qualifiers         {
 #         P642   [
 #             [0] {
 #                 datatype    "wikibase-item",
 #                 datavalue   {
 #                     type    "wikibase-entityid",
 #                     value   {
 #                         entity-type   "item",
 #                         id            "Q474741",
 #                         numeric-id    474741
 #                     }
 #                 },
 #                 property    "P642",
 #                 snaktype    "value"
 #             }
 #         ]
 #     },
 #     qualifiers-order   [
 #         [0] "P642"
 #     ],
 #     rank               "normal",
 #     references         [
 #         [0] {
 #             snaks         {
 #                 P214   [
 #                     [0] {
 #                         datatype    "external-id",
 #                         datavalue   {
 #                             type    "string",
 #                             value   113230702
 #                         },
 #                         property    "P214",
 #                         snaktype    "value"
 #                     }
 #                 ],
 #                 P248   [
 #                     [0] {
 #                         datatype    "wikibase-item",
 #                         datavalue   {
 #                             type    "wikibase-entityid",
 #                             value   {
 #                                 entity-type   "item",
 #                                 id            "Q53919",
 #                                 numeric-id    53919
 #                             }
 #                         },
 #                         property    "P248",
 #                         snaktype    "value"
 #                     }
 #                 ],
 #                 P813   [
 #                     [0] {
 #                         datatype    "time",
 #                         datavalue   {
 #                             type    "time",
 #                             value   {
 #                                 after           0,
 #                                 before          0,
 #                                 calendarmodel   "http://test.wikidata.org/entity/Q1985727",
 #                                 precision       11,
 #                                 time            "+2013-12-07T00:00:00Z",
 #                                 timezone        0
 #                             }
 #                         },
 #                         property    "P813",
 #                         snaktype    "value"
 #                     }
 #                 ]
 #             },
 #             snaks-order   [
 #                 [0] "P248",
 #                 [1] "P214",
 #                 [2] "P813"
 #             ]
 #         }
 #     ],
 #     type               "statement"
 # }

=head1 EXAMPLE2

 use strict;
 use warnings;

 use Wikibase::Datatype::Struct::Statement qw(struct2obj);

 # Item structure.
 my $struct_hr = {
         'id' => 'Q123$00C04D2A-49AF-40C2-9930-C551916887E8',
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
         'qualifiers' => {
                 'P642' => [{
                         'datatype' => 'wikibase-item',
                         'datavalue' => {
                                 'type' => 'wikibase-entityid',
                                 'value' => {
                                         'entity-type' => 'item',
                                         'id' => 'Q474741',
                                         'numeric-id' => 474741,
                                 },
                         },
                         'property' => 'P642',
                         'snaktype' => 'value',
                 }],
         },
         'qualifiers-order' => [
                 'P642',
         ],
         'rank' => 'normal',
         'references' => [{
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
         }],
         'type' => 'statement',
 };

 # Get object.
 my $obj = struct2obj($struct_hr);

 # Print out.
 print 'Id: '.$obj->id."\n";
 print 'Claim: '.$obj->snak->property.' -> '.$obj->snak->datavalue->value."\n";
 print "Qualifiers:\n";
 foreach my $property_snak (@{$obj->property_snaks}) {
         print "\t".$property_snak->property.' -> '.
                 $property_snak->datavalue->value."\n";
 }
 print "References:\n";
 foreach my $reference (@{$obj->references}) {
         print "\tReference:\n";
         foreach my $reference_snak (@{$reference->snaks}) {
                 print "\t\t".$reference_snak->property.' -> '.
                         $reference_snak->datavalue->value."\n";
         }
 }
 print 'Rank: '.$obj->rank."\n";

 # Output:
 # Id: Q123$00C04D2A-49AF-40C2-9930-C551916887E8
 # Claim: P31 -> Q5
 # Qualifiers:
 #         P642 -> Q474741
 # References:
 #         Reference:
 #                 P248 -> Q53919
 #                 P214 -> 113230702
 #                 P813 -> +2013-12-07T00:00:00Z
 # Rank: normal

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>,
L<Wikibase::Datatype::Statement>,
L<Wikibase::Datatype::Struct::Reference>,
L<Wikibase::Datatype::Struct::Snak>,
L<Wikibase::Datatype::Struct::Utils>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype::Struct>

Wikibase structure serialization.

=item L<Wikibase::Datatype::Statement>

Wikibase statement datatype.

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

0.07

=cut
