package Weather::Bug::Location;

use warnings;
use strict;
use Moose;
use XML::LibXML;

our $VERSION = '0.25';

has 'city' => ( is => 'ro', isa => 'Str', init_arg => '-city' );
has 'state' => ( is => 'ro', isa => 'Str', init_arg => '-state' );
has 'zipcode' => ( is => 'ro', isa => 'Str', init_arg => '-zip' );
has 'latitude' => ( is => 'ro', init_arg => '-lat', predicate => 'has_latitude' );
has 'longitude' => ( is => 'ro', init_arg => '-long', predicate => 'has_longitude' );
has 'distance' => ( is => 'ro', init_arg => '-dist', predicate => 'has_distance' );
has 'zone' => ( is => 'ro', init_arg => '-zone', predicate => 'has_zone' );

sub from_station_xml
{
    my $class = shift;
    my $node = shift;

    return Weather::Bug::Location->new(
        -city => $node->findvalue( '@city' ),
        -state => $node->findvalue( '@state' ),
        -zip => $node->findvalue( '@zipcode' ),
        -lat => $node->findvalue( '@latitude' ),
        -long => $node->findvalue( '@longitude' ),
        -dist => $node->findvalue( '@distance' ),
    );
}

sub from_compact_station_xml
{
    my $class = shift;
    my $node = shift;

    my $state = $node->findvalue( '@state' );
    $state =~ s/^\s+//;
    $state =~ s/\s+$//;
    return Weather::Bug::Location->new(
        -city => $node->findvalue( '@city' ),
        -state => $state,
        -zip => $node->findvalue( '@zipcode' ),
    );
}

sub from_obs_xml
{
    my $class = shift;
    my $node = shift;

    die "City/State not formatted as expected.\n"
        unless $node->findvalue( '.' ) =~ /^(.*?),\s+(\w\w)$/;
    my ($city,$state) = ($1,$2);

    return Weather::Bug::Location->new(
        -city => $city,
        -state => $state,
        -zip => $node->findvalue( '@zip' ),
    );
}

#
# Extract the station information from an aws:location node
#
# $locnode - the aws:location XML node
#
# Return a new Weather::Bug::Station object
sub from_forecast
{
    my $class = shift;
    my $node = shift;

    return Weather::Bug::Location->new(
        -city => $node->findvalue( 'aws:city' ),
        -state => $node->findvalue( 'aws:state' ),
        -zip => $node->findvalue( 'aws:zip' ),
        -zone => $node->findvalue( 'aws:zone' ),
    );
}

sub is_equivalent
{
    my $self = shift;
    my $other = shift;

    return unless $other->isa( __PACKAGE__ );
    # Compare required fields
    return unless $self->city() eq $other->city();
    return unless $self->state() eq $other->state();
    return unless $self->zipcode() eq $other->zipcode();

    # optional fields match if one is missing.
    return unless !$self->has_latitude() or !$other->has_latitude()
        or $self->latitude() == $other->latitude();
    return unless !$self->has_longitude() or !$other->has_longitude()
        or $self->longitude() == $other->longitude();
    return unless !$self->has_distance() or !$other->has_distance()
        or $self->distance() == $other->distance();
    return unless !$self->has_zone() or !$other->has_zone()
        or $self->zone() eq $other->zone();

    return 1;
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Weather::Bug::Location - Simple class interface to the location of
a WeatherBug Station or observation.

=head1 VERSION

This document describes Weather::Bug::Location version 0.25

=head1 SYNOPSIS

    use Weather::Bug;

    my $wbug = Weather::Bug->new( 'YOURAPIKEYHERE' );
    my ($station) = $wbug->list_stations( 77096 );
    my $l = $station->location();

    printf( "%s, %s %s\n\t(%0.5f,%0.5f), (dist=%0.3f)\n",
            $l->city(), $l->state(), $l->zipcode(),
            $l->latitude(), $l->longitude(),
            $l->distance()
    );

=head1 DESCRIPTION

Each type of response has its own concept of what Location information should
look like. This class abstracts away the differences (as much as possible)
providing a mostly common interface. Unfortunately, some of the responses
provide more information than others, so it is not always possible to get
all of the same information from each Location object.

The Location object should always provide three pieces of information: I<city>,
I<state>, and I<zipcode>. Depending on where it was obtained, it may also
contain I<latitude> and I<longitude> of the site, I<distance> from the center
of the requested zip code, and/or a I<zone> string representing a general
location in the US.

Each field has its own accessor method. If the field is optional, it will also
have a I<has_> method that tells whether or not the field is present.

=head1 INTERFACE 

The Location is basically a data object that only provides read access to its
fields. The methods of this class can be separated into two groups, accessor
methods and factory methods.

=head2 Accessor Methods

The methods providing access to the Location's fields are:

=over 4

=item city

The Location's city as a string. Always available.

=item state

The Location's state as a string. Always available.

=item zipcode

The Location's zip code as a string. Always available.

=item has_latitude

Boolean value telling whether or not I<latitude> is available.

=item latitude

The Location's latitude as a float. Always available.

=item has_longitude

Boolean value telling whether or not I<longitude> is available.

=item longitude

The Location's longitude as a float. Always available.

=item has_distance

Boolean value telling whether or not I<distance> is available.

=item distance

The Location's distance from the center of the zip code as a float. Always available.

=item has_zone

Boolean value telling whether or not I<zone> is available.

=item zone

A string telling the general region of the US that the Location describes.

=item is_equivalent

Returns a true value if the supplied Location is equvalent.

    $loc->is_equivalent( $other );

Equivalence, in this case, is defined as all of the required fields are the same.
The optional fields are also tested in the case where both of the Location objects
do have that field. So, if either Location is missing a field (say, distance) this
field will not be compared.

=back

=head2 Factory Methods

Since the object is usually created from an XML repsonse, the class provides
factory methods that take a portion of the XML and return a Location.

=over 4

=item from_station_xml

Construct a Location from the C<aws:station> node returned by the I<getStations>
API method. The only argument is the node to parse.

The created Location will have the following fields: city, state, zipcode,
latitude, longitude, and distance (from the center of the zipcode supplied to
getStations).

Returns a Location object on success.

=item from_forecast

Construct a Location object from the C<aws:location> node returned by the
I<getFullForecast> API method. The only argument is the node to parse.

The created Location will have the following fields: city, state, zipcode,
and zone.

Returns a Location object on success.

=item from_compact_station_xml

=item from_obs_xml

Construct a Location object from a I<getLiveWeather> request.

Returns a Location object on success or dies if the city and state cannot be
parsed.

=back

=head1 DIAGNOSTICS

=over

=item C<< City/State not formatted as expected. >>

The Live Weather mixes the City and State together in one node value. This
value was not formatted in a way that allowed the module to parse the result.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Weather::Bug requires no configuration files or environment variables.

=head1 DEPENDENCIES

C<Moose>, C<XML::LibXML>.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-weather-weatherbug@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

G. Wade Johnson  C<< <wade@anomaly.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, G. Wade Johnson C<< <wade@anomaly.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
