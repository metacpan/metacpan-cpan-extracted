package Weather::Bug::CompactWeather;

use warnings;
use strict;
use Moose;
use XML::LibXML;
use Weather::Bug::Station;
use Weather::Bug::Temperature;
use Weather::Bug::Quantity;

our $VERSION = '0.25';

has 'station' => ( is => 'ro', isa => 'Weather::Bug::Station', init_arg => '-station' );
has 'temp' => ( is => 'ro', isa => 'Weather::Bug::Temperature', init_arg => '-temp' );
has 'rain_today' => ( is => 'ro', isa => 'Weather::Bug::Quantity', init_arg => '-rain_today' );
has 'wind_speed' => ( is => 'ro', isa => 'Weather::Bug::Quantity', init_arg => '-wind_speed' );
has 'wind_dir' => ( is => 'ro', isa => 'Str', init_arg => '-wind_dir' );
has 'gust_speed' => ( is => 'ro', isa => 'Weather::Bug::Quantity', init_arg => '-gust_speed' );
has 'gust_dir' => ( is => 'ro', isa => 'Str', init_arg => '-gust_dir' );

sub from_xml
{
    my $class = shift;
    my $w = shift;
    my $creator = shift;

    if( $creator->isa( 'Weather::Bug' ) ) {
        my ($station) = $w->findnodes( 'aws:station' );
        $creator = Weather::Bug::Station->from_compact_xml(
            $creator, $station
        );
    }
    die "Unable to create a Station localizing the CompactWeather.\n"
        unless $creator->isa( 'Weather::Bug::Station' );

    return Weather::Bug::CompactWeather->new(
        -station => $creator,
        -temp => Weather::Bug::Temperature->from_xml( ($w->findnodes( 'aws:temp' ))[0] ),
        -rain_today => Weather::Bug::Quantity->from_xml( ($w->findnodes( 'aws:rain-today' ))[0] ),
        -wind_speed => Weather::Bug::Quantity->from_xml( ($w->findnodes( 'aws:wind-speed' ))[0] ),
        -wind_dir => $w->findvalue( 'aws:wind-direction' ),
        -gust_speed => Weather::Bug::Quantity->from_xml( ($w->findnodes( 'aws:gust-speed' ))[0] ),
        -gust_dir => $w->findvalue( 'aws:gust-direction' ),
    );
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Weather::Bug::CompactWeather - Simple class interface for a compact weather report.

=head1 VERSION

This document describes Weather::Bug::CompactWeather version 0.25

=head1 SYNOPSIS

    use Weather::Bug;

    my $wbug = Weather::Bug->new( 'YOURAPIKEYHERE' );
    my $weather = $wbug->get_live_compact_weather( 'HSTMU', 77030 );

    my $temp = $weather->temp();
    my $rain = $weather->rain_today();
    my $wind = $weather->wind_speed();
    my $dir = $weather->wind_dir();
    print "Temperature: $temp\n",
          "Rain: $rain\n",
          "Wind: $wind from $dir\n";

=head1 DESCRIPTION

The CompactWeather class wraps the concept of a WeatherBug weather report.
The WeatherBug API provides two different weather reports: Live Compact, and Live.
This object wraps the compact form which contains the basic information you may
want from a weather observation.

=head1 INTERFACE 

The CompactWeather interface provides a factory method that constructs the
object from an XML node. It also provides accessor methods for the various
pieces of data comprising the weather observation.

=head2 Factory Method

Since the CompactWeather object will almost always be created from an XML stream,
this class provides a method for constructing a CompactWeather object from
the XML response.

=over 4

=item from_xml

Extract the weather information from an C<aws:weather> node, such as the
ones returned by the I<getLiveCompactWeather> WeatherBug request. 

$bug - the L<Weather::Bug> object
$w - the C<aws:weather> XML node
$creator - either a L<Weather::Bug::Station> or a C<Weather::Bug> object.

If we get a Station, use it internally, otherwise we need to parse the
XML to create a station object.

Return a new L<Weather::Bug::CompactWeather> object. Dies on failure.

=back

=head2 Accessor Methods

The CompactWeather object provides accessor methods for the following fields:

=over 4

=item station

A L<Weather::Bug::Station> object describing the location of the observation.
The amount of information in this Station object is determined by how the
CompactWeather was created. L<Weather::Bug::Station::get_live_compact_weather>
returns the Station used in the request. L<Weather::Bug::get_live_compact_weather>
returns a simpler Station object created from the XML stream.

=item temp

A L<Weather::Bug::Temperature> object containing the current temperature.

=item rain_today

A L<Weather::Bug::Quantity> object containing the amount of rainfall detected
today.

=item wind_speed

A L<Weather::Bug::Quantity> object containing the current sustained windspeed.

=item wind_dir

A string listing the current sustained wind direction.

=item gust_speed

A L<Weather::Bug::Quantity> object containing the windspeed of the most recent
gust.

=item gust_dir

A string listing the direction of the most recent wind gust.

=back

=head1 DIAGNOSTICS

=over 4

=item C<< Unable to create a Station localizing the CompactWeather. >>

The from_xml method was unable to create a Station object from
the incoming XML or the creator object was neither a L<Weather::Bug> nor
a L<Weather::Bug::Station> object.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Weather::Bug requires no configuration files or environment variables.

=head1 DEPENDENCIES

C<Moose>, C<XML::LibXML>

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
