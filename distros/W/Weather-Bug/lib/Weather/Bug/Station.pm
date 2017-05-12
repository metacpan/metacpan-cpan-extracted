package Weather::Bug::Station;

use warnings;
use strict;
use Moose;
use XML::LibXML;
use Weather::Bug;
use Weather::Bug::Location;
use Weather::Bug::Temperature;
use Weather::Bug::Quantity;
use Weather::Bug::CompactWeather;
use Weather::Bug::Weather;

our $VERSION = '0.25';

has 'id' => ( is => 'ro', isa => 'Str', init_arg => '-id' );
has 'name' => ( is => 'ro', isa => 'Str', init_arg => '-name' );
has 'url' => ( is => 'ro', isa => 'Str', init_arg => '-url', predicate => 'has_url' );
has 'location' => ( is => 'ro', isa => 'Weather::Bug::Location', init_arg => '-loc' );
has 'station_type' => ( is => 'ro', isa => 'Str', init_arg => '-type' );
has 'bug' => ( is => 'ro', isa => 'Weather::Bug', init_arg => '-bug' );

sub from_xml
{
    my $class = shift;
    my $bug = shift;
    my $statnode = shift;

    return Weather::Bug::Station->new(
        -id => $statnode->findvalue( '@id' ),
        -name => $statnode->findvalue( '@name' ),
        -loc => Weather::Bug::Location->from_station_xml( $statnode ),
        -type => $statnode->findvalue( '@station-type' ),
        -bug => $bug,
    );
}

sub from_compact_xml
{
    my $class = shift;
    my $bug = shift;
    my $statnode = shift;

    return Weather::Bug::Station->new(
        -id => $statnode->findvalue( '@id' ),
        -name => $statnode->findvalue( '@name' ),
        -loc => Weather::Bug::Location->from_compact_station_xml( $statnode ),
        -type => $statnode->findvalue( '@station-type' ),
        -bug => $bug,
    );
}

sub from_obs_xml
{
    my $class = shift;
    my $bug = shift;
    my $node = shift;

    return Weather::Bug::Station->new(
        -id => $node->findvalue( 'aws:station-id' ),
        -name => $node->findvalue( 'aws:station' ),
        -loc => Weather::Bug::Location->from_obs_xml( ($node->findnodes( 'aws:city-state' ))[0] ),
        -url => $node->findvalue( 'aws:site-url' ),
        -bug => $bug,
    );
}

#
# Utility method that simplifies calling the WeatherBug::request method for
# the API requests associated with the Station object.
#
# $cmd - command name
#
# Returns the XML response as a string if successful, or C<undef> on failure.
sub _request
{
    my $self = shift;
    my $cmd = shift;

    return $self->{bug}->request(
        $cmd, { zipcode => $self->location()->zipcode,
                StationId => $self->id }
    );
}

sub is_equivalent
{
    my $self = shift;
    my $other = shift;

    return unless $other->isa( __PACKAGE__ );
    return unless $self->id() eq $other->id();
    return unless $self->name() eq $other->name();
    return unless $self->station_type() eq $other->tation_type();
    return if $self->has_url() and $other->has_url and
        $self->url() ne $other->url();
    return $self->location()->is_equivalent( $other->location() );
}

sub get_live_weather
{
    my $self = shift;
    my $response = $self->_request( 'getLiveWeather' );

    my $p = XML::LibXML->new();
    my $doc = $p->parse_string( $response );

    my ($ob) = $doc->findnodes( '//aws:ob' );
    return Weather::Bug::Weather->from_xml( $ob, $self );
}

sub get_live_compact_weather
{
    my $self = shift;
    my $response = $self->_request( 'getLiveCompactWeather' );

    my $p = XML::LibXML->new();
    my $doc = $p->parse_string( $response );
    my ($w) = $doc->findnodes( '//aws:weather' );
    return Weather::Bug::CompactWeather->from_xml( $w, $self );
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Weather::Bug::Station - Simple class interface to the WeatherBug station
data

=head1 VERSION

This document describes Weather::Bug::Station version 0.25

=head1 SYNOPSIS

    use Weather::Bug;

    my $wbug = Weather::Bug->new( 'YOURAPIKEYHERE' );
    my @stations = $wbug->list_stations( 77096 );

    for my $s (@stations)
    {
        my $l = $s->location();
        printf( "%s: %s\n\tin %s, %s %s\n\t(%0.5f,%0.5f), (dist=%0.3f, type=%s)\n",
                $s->id(), $s->name(),
                $l->city(), $l->state(), $l->zipcode(),
                $l->latitude(), $l->longitude(),
                $l->distance(), $l->station_type()
        );
    }

=head1 DESCRIPTION

The Station class wraps the concept of a WeatherBug station. A Station
object provides some information about its location and identity. Since
actual weather observations are made at particular stations, this object
also supplies the methods needed to request the current weather.

=head1 INTERFACE 

The Station interface can be divided into three groups of methods: factory
methods, accessor methods, and request methods.

=head2 Factory Methods

Since the Station object will almost always be created from an XML stream,
this class provides a set of methods for constructing a Station object from
the XML responses.

=over 4

=item from_xml

Extract the station information from an aws:station node, such as the
ones returned by the I<getStations> WeatherBug request. 

=over 4

=item $bug

the Weather::Bug object

=item $statnode

the aws:station XML node

=back

Return a new Weather::Bug::Station object on success.

=item from_compact_xml

Extract the station information from an C<aws:weather> node, such as the
ones returned by the I<getLiveCompactWeather> WeatherBug request. 

=over 4

=item $bug

the Weather::Bug object

=item $statnode

the C<aws:weather> XML node

=back

Return a new Weather::Bug::Station object on success.

=item from_obs_xml

Extract the station information from an C<aws:obs> node, such as the
ones returned by the I<getLiveWeather> WeatherBug request. 

=over 4

=item $bug

the L<Weather::Bug> object

=item $statnode

the C<aws:obs> XML node

=back

Return a new Weather::Bug::Station object on success.

=back

=head2 Accessor Methods

The Station object provides accessor methods for the following fields:

=over 4

=item id

This is the short ID string that can be used to refer to a particular
WeatherBug station.

=item name

This is a longer printable name for the WeatherBug station.

=item location

This is a L<Weather::Bug::Location> object that describes the
location of the station.

=item station_type

This is a string telling what kind of station this is. This value appears
to be either I<WeatherBug> or I<NWS> (National Weather Service). 

=item url

An optional URL associated with the Station returned as a string.

=item has_url

A boolean method that returns a true value if the Station has an associated
URL.

=item is_equivalent

Returns true if all of the required elements of the Station match those
of the other Station and if both Stations have a URL, they match.

=back

=head2 Request Methods

=over 4

=item get_live_weather

Perform a request on this Station to get the live weather. A
L<Weather::Bug::Weather> object representing the current weather is returned.

=item get_live_compact_weather

Perform a request on this Station to get the compact version of the live weather.
A L<Weather::Bug::CompactWeather> object representing the current weather is returned.

=back

=over

=item C<< Request for '%s' failed. >>

The request to the WeatherBug API was not successful. The C<%s> is the
name of the page that failed.

=item C<< Unable to parse output from '%s' request. >>

Although the WeatherBug API did return successfully, the output could not
be parsed as well-formed XML. The C<%s> is the name of the page that failed.

=item C<< No '%s' node found. >>

Although the WeatherBug API did return successfully, the output XML did not contain
the specified node.

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
