package Wikibase::Datatype::Struct::MediainfoStatement;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Wikibase::Datatype::MediainfoStatement;
use Wikibase::Datatype::Struct::MediainfoSnak;
use Wikibase::Datatype::Struct::Reference;
use Wikibase::Datatype::Struct::Utils qw(obj_array_ref2struct struct2snaks_array_ref);

Readonly::Array our @EXPORT_OK => qw(obj2struct struct2obj);

our $VERSION = 0.12;

sub obj2struct {
	my ($obj, $base_uri) = @_;

	if (! defined $obj) {
		err "Object doesn't exist.";
	}
	if (! $obj->isa('Wikibase::Datatype::MediainfoStatement')) {
		err "Object isn't 'Wikibase::Datatype::MediainfoStatement'.";
	}
	if (! defined $base_uri) {
		err 'Base URI is required.';
	}

	my $struct_hr = {
		defined $obj->id ? ('id' => $obj->id) : (),
		'mainsnak' => Wikibase::Datatype::Struct::MediainfoSnak::obj2struct($obj->snak, $base_uri),
		@{$obj->property_snaks} ? (
			%{obj_array_ref2struct($obj->property_snaks, 'qualifiers', $base_uri,
			'Wikibase::Datatype::MediainfoSnak', 'Wikibase::Datatype::Struct::MediainfoSnak')},
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

	my $obj = Wikibase::Datatype::MediainfoStatement->new(
		exists $struct_hr->{'id'} ? ('id' => $struct_hr->{'id'}) : (),
		'property_snaks' => struct2snaks_array_ref($struct_hr, 'qualifiers',
			'Wikibase::Datatype::Struct::MediainfoSnak'),
		'snak' => Wikibase::Datatype::Struct::MediainfoSnak::struct2obj($struct_hr->{'mainsnak'}),
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

Wikibase::Datatype::Struct::MediainfoStatement - Wikibase mediainfo statement structure serialization.

=head1 SYNOPSIS

 use Wikibase::Datatype::Struct::MediainfoStatement qw(obj2struct struct2obj);

 my $struct_hr = obj2struct($obj, $base_uri);
 my $obj = struct2obj($struct_hr);

=head1 DESCRIPTION

This conversion is between objects defined in Wikibase::Datatype and structures
serialized via JSON to MediaWiki.

=head1 SUBROUTINES

=head2 C<obj2struct>

 my $struct_hr = obj2struct($obj, $base_uri);

Convert Wikibase::Datatype::MediainfoStatement instance to structure.
C<$base_uri> is base URI of Wikibase system (e.g. http://test.wikidata.org/entity/).

Returns reference to hash with structure.

=head2 C<struct2obj>

 my $obj = struct2obj($struct_hr);

Convert structure of mediainfo statement to object.

Returns Wikibase::Datatype::MediainfoStatement instance.

=head1 ERRORS

 obj2struct():
         Base URI is required.
         Object doesn't exist.
         Object isn't 'Wikibase::Datatype::MediainfoStatement'.

=head1 EXAMPLE1

=for comment filename=obj2struct_mediainfo_statement.pl

 use strict;
 use warnings;

 use Data::Printer;
 use Wikibase::Datatype::MediainfoSnak;
 use Wikibase::Datatype::MediainfoStatement;
 use Wikibase::Datatype::Struct::MediainfoStatement qw(obj2struct);
 use Wikibase::Datatype::Value::Item;

 # Object.
 my $obj = Wikibase::Datatype::MediainfoStatement->new(
         'id' => 'M123$00C04D2A-49AF-40C2-9930-C551916887E8',

         # instance of (P31) human (Q5)
         'snak' => Wikibase::Datatype::MediainfoSnak->new(
                  'datavalue' => Wikibase::Datatype::Value::Item->new(
                          'value' => 'Q5',
                  ),
                  'property' => 'P31',
         ),
         'property_snaks' => [
                 # of (P642) alien (Q474741)
                 Wikibase::Datatype::MediainfoSnak->new(
                          'datavalue' => Wikibase::Datatype::Value::Item->new(
                                  'value' => 'Q474741',
                          ),
                          'property' => 'P642',
                 ),
         ],
 );

 # Get structure.
 my $struct_hr = obj2struct($obj, 'http://test.wikidata.org/entity/');

 # Dump to output.
 p $struct_hr;

 # Output:
 # \ {
 #     id                 "M123$00C04D2A-49AF-40C2-9930-C551916887E8",
 #     mainsnak           {
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
 #     type               "statement"
 # }

=head1 EXAMPLE2

=for comment filename=struct2obj_mediainfo_statement.pl

 use strict;
 use warnings;

 use Wikibase::Datatype::Struct::MediainfoStatement qw(struct2obj);

 # Item structure.
 my $struct_hr = {
         'id' => 'M123$00C04D2A-49AF-40C2-9930-C551916887E8',
         'mainsnak' => {
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
         'type' => 'statement',
 };

 # Get object.
 my $obj = struct2obj($struct_hr);

 # Print out.
 print 'Id: '.$obj->id."\n";
 print 'Statements: '.$obj->snak->property.' -> '.$obj->snak->datavalue->value."\n";
 print "Qualifiers:\n";
 foreach my $property_snak (@{$obj->property_snaks}) {
         print "\t".$property_snak->property.' -> '.
                 $property_snak->datavalue->value."\n";
 }
 print 'Rank: '.$obj->rank."\n";

 # Output:
 # Id: M123$00C04D2A-49AF-40C2-9930-C551916887E8
 # Statements: P31 -> Q5
 # Qualifiers:
 #         P642 -> Q474741
 # Rank: normal

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>,
L<Wikibase::Datatype::MediainfoStatement>,
L<Wikibase::Datatype::Struct::Reference>,
L<Wikibase::Datatype::Struct::Snak>,
L<Wikibase::Datatype::Struct::Utils>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype::Struct>

Wikibase structure serialization.

=item L<Wikibase::Datatype::Statement>

Wikibase statement datatype.

=item L<Wikibase::Datatype::MediainfoStatement>

Wikibase mediainfo statement datatype.

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

0.12

=cut
