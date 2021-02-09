package Wikibase::Datatype::Struct::Value::Globecoordinate;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use URI;
use Wikibase::Datatype::Value::Globecoordinate;

Readonly::Array our @EXPORT_OK => qw(obj2struct struct2obj);

our $VERSION = 0.08;

sub obj2struct {
	my ($obj, $base_uri) = @_;

	if (! defined $obj) {
		err "Object doesn't exist.";
	}
	if (! $obj->isa('Wikibase::Datatype::Value::Globecoordinate')) {
		err "Object isn't 'Wikibase::Datatype::Value::Globecoordinate'.";
	}
	if (! defined $base_uri) {
		err 'Base URI is required.';
	}

	my $struct_hr = {
		'value' => {
			'altitude' => $obj->altitude ? $obj->altitude : 'null',
			'globe' => $base_uri.$obj->globe,
			'latitude' => $obj->latitude,
			'longitude' => $obj->longitude,
			'precision' => $obj->precision,
		},
		'type' => $obj->type,
	};

	return $struct_hr;
}

sub struct2obj {
	my $struct_hr = shift;

	if (! exists $struct_hr->{'type'}
		|| $struct_hr->{'type'} ne 'globecoordinate') {

		err "Structure isn't for 'globecoordinate' datatype.";
	}

	my $u = URI->new($struct_hr->{'value'}->{'globe'});
	my @path_segments = $u->path_segments;
	my $globe = $path_segments[-1];
	my $obj = Wikibase::Datatype::Value::Globecoordinate->new(
		defined $struct_hr->{'value'}->{'altitude'} ? (
			'altitude' => $struct_hr->{'value'}->{'altitude'},
		) : (),
		'globe' => $globe,
		'precision' => $struct_hr->{'value'}->{'precision'},
		'value' => [
			$struct_hr->{'value'}->{'latitude'},
			$struct_hr->{'value'}->{'longitude'},
		],
	);

	return $obj;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Struct::Value::Globecoordinate - Wikibase globe coordinate structure serialization.

=head1 SYNOPSIS

 use Wikibase::Datatype::Struct::Value::Globecoordinate qw(obj2struct struct2obj);

 my $struct_hr = obj2struct($obj, $base_uri);
 my $obj = struct2obj($struct_hr);

=head1 DESCRIPTION

This conversion is between objects defined in Wikibase::Datatype and structures
serialized via JSON to MediaWiki.

=head1 SUBROUTINES

=head2 C<obj2struct>

 my $struct_hr = obj2struct($obj, $base_uri);

Convert Wikibase::Datatype::Value::Globecoordinate instance to structure.
C<$base_uri> is base URI of Wikibase system (e.g. http://test.wikidata.org/entity/).

Returns reference to hash with structure.

=head2 C<struct2obj>

 my $obj = struct2obj($struct_hr);

Convert structure of item to object.

Returns Wikibase::Datatype::Value::Globecoordinate instance.

=head1 ERRORS

 obj2struct():
         Base URI is required.
         Object doesn't exist.
         Object isn't 'Wikibase::Datatype::Value::Globecoordinate'.

 struct2obj():
         Structure isn't for 'globecoordinate' datatype.

=head1 EXAMPLE1

 use strict;
 use warnings;

 use Data::Printer;
 use Wikibase::Datatype::Value::Globecoordinate;
 use Wikibase::Datatype::Struct::Value::Globecoordinate qw(obj2struct);

 # Object.
 my $obj = Wikibase::Datatype::Value::Globecoordinate->new(
         'value' => [49.6398383, 18.1484031],
 );

 # Get structure.
 my $struct_hr = obj2struct($obj, 'http://test.wikidata.org/entity/');

 # Dump to output.
 p $struct_hr;

 # Output:
 # \ {
 #     type    "globecoordinate",
 #     value   {
 #         altitude    "null",
 #         globe       "http://test.wikidata.org/entity/Q2",
 #         latitude    49.6398383,
 #         longitude   18.1484031,
 #         precision   1e-07
 #     }
 # }

=head1 EXAMPLE2

 use strict;
 use warnings;

 use Wikibase::Datatype::Struct::Value::Globecoordinate qw(struct2obj);

 # Globe coordinate structure.
 my $struct_hr = {
         'type' => 'globecoordinate',
         'value' => {
                 'altitude' => 'null',
                 'globe' => 'http://test.wikidata.org/entity/Q2',
                 'latitude' => 49.6398383,
                 'longitude' => 18.1484031,
                 'precision' => 1e-07,
         },
 };

 # Get object.
 my $obj = struct2obj($struct_hr);

 # Get globe.
 my $globe = $obj->globe;

 # Get longitude.
 my $longitude = $obj->longitude;

 # Get latitude.
 my $latitude = $obj->latitude;

 # Get precision.
 my $precision = $obj->precision;

 # Get type.
 my $type = $obj->type;

 # Get value.
 my $value_ar = $obj->value;

 # Print out.
 print "Globe: $globe\n";
 print "Latitude: $latitude\n";
 print "Longitude: $longitude\n";
 print "Precision: $precision\n";
 print "Type: $type\n";
 print 'Value: '.(join ', ', @{$value_ar})."\n";

 # Output:
 # Globe: Q2
 # Latitude: 49.6398383
 # Longitude: 18.1484031
 # Precision: 1e-07
 # Type: globecoordinate
 # Value: 49.6398383, 18.1484031

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>,
L<URI>,
L<Wikibase::Datatype::Value::Globecoordinate>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype::Struct>

Wikibase structure serialization.

=item L<Wikibase::Datatype::Value::Globecoordinate>

Wikibase globe coordinate value datatype.

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
