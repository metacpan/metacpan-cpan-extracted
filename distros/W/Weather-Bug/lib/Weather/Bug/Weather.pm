package Weather::Bug::Weather;

use warnings;
use strict;
use Moose;
use Moose::Util::TypeConstraints;
use XML::LibXML;
use Weather::Bug::Station;
use Weather::Bug::Temperature;
use Weather::Bug::Quantity;
use DateTime;

our $VERSION = '0.25';

subtype 'DateTime' => as 'Object' => where { $_->isa('DateTime') };

has 'date' => ( is => 'ro', isa => 'DateTime', init_arg => '-date' );
has 'station' => ( is => 'ro', isa => 'Weather::Bug::Station', init_arg => '-station' );

has 'aux_temp' => ( is => 'ro', isa => 'Weather::Bug::Temperature', init_arg => '-aux_temp' );
has 'aux_temp_rate' => ( is => 'ro', isa => 'Weather::Bug::Temperature', init_arg => '-aux_rate' );
has 'dew_point' => ( is => 'ro', isa => 'Weather::Bug::Temperature', init_arg => '-dewpt' );

has 'elevation' => ( is => 'ro', isa => 'Weather::Bug::Quantity', init_arg => '-elevation' );
has 'feels_like' => ( is => 'ro', isa => 'Weather::Bug::Temperature', init_arg => '-feels' );

has 'gust_time' => ( is => 'ro', isa => 'DateTime', init_arg => '-gust_time' );
has 'gust_speed' => ( is => 'ro', isa => 'Weather::Bug::Quantity', init_arg => '-gust_speed' );
has 'gust_dir' => ( is => 'ro', isa => 'Str', init_arg => '-gust_dir' );

has 'humidity' => ( is => 'ro', isa => 'Weather::Bug::Quantity', init_arg => '-humidity' );
has 'humidity_high' => ( is => 'ro', isa => 'Weather::Bug::Quantity', init_arg => '-humidity_high' );
has 'humidity_low' => ( is => 'ro', isa => 'Weather::Bug::Quantity', init_arg => '-humidity_low' );
has 'humidity_rate' => ( is => 'ro', isa => 'Num', init_arg => '-humidity_rate' );

has 'indoor_temp' => ( is => 'ro', isa => 'Weather::Bug::Temperature', init_arg => '-indoor_temp' );
has 'indoor_temp_rate' => ( is => 'ro', isa => 'Weather::Bug::Temperature', init_arg => '-indoor_temp_rate' );

has 'light' => ( is => 'ro', isa => 'Num', init_arg => '-light' );
has 'light_rate' => ( is => 'ro', isa => 'Num', init_arg => '-light_rate' );

has 'moon_phase' => ( is => 'ro', isa => 'Num', init_arg => '-moon_phase' );
has 'moon_phase_img' => ( is => 'ro', isa => 'Str', init_arg => '-moon_phase_img' );

has 'pressure' => ( is => 'ro', isa => 'Weather::Bug::Quantity', init_arg => '-pressure' );
has 'pressure_high' => ( is => 'ro', isa => 'Weather::Bug::Quantity', init_arg => '-pressure_high' );
has 'pressure_low' => ( is => 'ro', isa => 'Weather::Bug::Quantity', init_arg => '-pressure_low' );
has 'pressure_rate' => ( is => 'ro', isa => 'Num', init_arg => '-pressure_rate' );

has 'rain_month' => ( is => 'ro', isa => 'Weather::Bug::Quantity', init_arg => '-rain_month' );
has 'rain_rate' => ( is => 'ro', isa => 'Weather::Bug::Quantity', init_arg => '-rain_rate' );
has 'rain_rate_max' => ( is => 'ro', isa => 'Weather::Bug::Quantity', init_arg => '-rain_rate_max' );
has 'rain_today' => ( is => 'ro', isa => 'Weather::Bug::Quantity', init_arg => '-rain_today' );
has 'rain_year' => ( is => 'ro', isa => 'Weather::Bug::Quantity', init_arg => '-rain_year' );

has 'temp' => ( is => 'ro', isa => 'Weather::Bug::Temperature', init_arg => '-temp' );
has 'temp_high' => ( is => 'ro', isa => 'Weather::Bug::Temperature', init_arg => '-temp_high' );
has 'temp_low' => ( is => 'ro', isa => 'Weather::Bug::Temperature', init_arg => '-temp_low' );
has 'temp_rate' => ( is => 'ro', isa => 'Weather::Bug::Temperature', init_arg => '-temp_rate' );

has 'sunrise' => ( is => 'ro', isa => 'DateTime', init_arg => '-sunrise' );
has 'sunset' => ( is => 'ro', isa => 'DateTime', init_arg => '-sunset' );

has 'wet_bulb' => ( is => 'ro', isa => 'Weather::Bug::Temperature', init_arg => '-wetbulb' );

has 'wind_speed' => ( is => 'ro', isa => 'Weather::Bug::Quantity', init_arg => '-wind_speed' );
has 'wind_speed_avg' => ( is => 'ro', isa => 'Weather::Bug::Quantity', init_arg => '-wind_speed_avg' );
has 'wind_dir' => ( is => 'ro', isa => 'Str', init_arg => '-wind_dir' );
has 'wind_dir_avg' => ( is => 'ro', isa => 'Str', init_arg => '-wind_dir_avg' );

sub _parse_datetime
{
    my $node = shift;

    my $tz = $node->findvalue( 'aws:time-zone/@offset' );
    if( length $tz )
    {
        $tz *= 100 if -30 < $tz && $tz < 30;
        $tz = sprintf '%+05d', $tz;
    }
    else
    {
        $tz = "floating";
    }

    return DateTime->new(
        year => $node->findvalue( 'aws:year/@number' ),
        month => $node->findvalue( 'aws:month/@number' ),
        day => $node->findvalue( 'aws:day/@number' ),
        hour => $node->findvalue( 'aws:hour/@hour-24' ),
        minute => $node->findvalue( 'aws:minute/@number' ),
        second => $node->findvalue( 'aws:second/@number' ),
        time_zone => $tz,
    );
}

sub from_xml
{
    my $class = shift;
    my $w = shift;
    my $creator = shift;

    if( $creator->isa( 'Weather::Bug' ) ) {
        $creator = Weather::Bug::Station->from_obs_xml( $creator, $w );
    }
    die "Unable to create a Station localizing the Weather.\n"
        unless $creator->isa( 'Weather::Bug::Station' );

    return Weather::Bug::Weather->new(
        -date => _parse_datetime( ($w->findnodes( 'aws:ob-date' ))[0] ),
        -station => $creator,

        -aux_temp => Weather::Bug::Temperature->from_xml( ($w->findnodes( 'aws:aux-temp' ))[0] ),
        -aux_rate => Weather::Bug::Temperature->from_xml( ($w->findnodes( 'aws:aux-temp-rate' ))[0] ),
        -dewpt => Weather::Bug::Temperature->from_xml( ($w->findnodes( 'aws:dew-point' ))[0] ),

        -elevation => Weather::Bug::Quantity->from_xml( ($w->findnodes( 'aws:elevation' ))[0] ),
        -feels => Weather::Bug::Temperature->from_xml( ($w->findnodes( 'aws:feels-like' ))[0] ),

        -gust_time => _parse_datetime( ($w->findnodes( 'aws:gust-time' ))[0] ),
        -gust_speed => Weather::Bug::Quantity->from_xml( ($w->findnodes( 'aws:gust-speed' ))[0] ),
        -gust_dir => $w->findvalue( 'aws:gust-direction' ),

        -humidity => Weather::Bug::Quantity->from_xml( ($w->findnodes( 'aws:humidity' ))[0] ),
        -humidity_high => Weather::Bug::Quantity->from_xml( ($w->findnodes( 'aws:humidity-high' ))[0] ),
        -humidity_low => Weather::Bug::Quantity->from_xml( ($w->findnodes( 'aws:humidity-low' ))[0] ),
        -humidity_rate => $w->findvalue( 'aws:humidity-rate' ),

        -indoor_temp => Weather::Bug::Temperature->from_xml( ($w->findnodes( 'aws:indoor-temp' ))[0] ),
        -indoor_temp_rate => Weather::Bug::Temperature->from_xml( ($w->findnodes( 'aws:indoor-temp-rate' ))[0] ),

        -light => $w->findvalue( 'aws:light' ),
        -light_rate => $w->findvalue( 'aws:light-rate' ),

        -moon_phase => $w->findvalue( 'aws:moon-phase' ),
        -moon_phase_img => $w->findvalue( 'aws:moon-phase/@moon-phase-img' ),

        -pressure => Weather::Bug::Quantity->from_xml( ($w->findnodes( 'aws:pressure' ))[0] ),
        -pressure_high => Weather::Bug::Quantity->from_xml( ($w->findnodes( 'aws:pressure-high' ))[0] ),
        -pressure_low => Weather::Bug::Quantity->from_xml( ($w->findnodes( 'aws:pressure-low' ))[0] ),
        -pressure_rate => $w->findvalue( 'aws:pressure-rate' ),

        -rain_month => Weather::Bug::Quantity->from_xml( ($w->findnodes( 'aws:rain-month' ))[0] ),
        -rain_rate => Weather::Bug::Quantity->from_xml( ($w->findnodes( 'aws:rain-rate' ))[0] ),
        -rain_rate_max => Weather::Bug::Quantity->from_xml( ($w->findnodes( 'aws:rain-rate-max' ))[0] ),
        -rain_today => Weather::Bug::Quantity->from_xml( ($w->findnodes( 'aws:rain-today' ))[0] ),
        -rain_year => Weather::Bug::Quantity->from_xml( ($w->findnodes( 'aws:rain-year' ))[0] ),

        -temp => Weather::Bug::Temperature->from_xml( ($w->findnodes( 'aws:temp' ))[0] ),
        -temp_high => Weather::Bug::Temperature->from_xml( ($w->findnodes( 'aws:temp-high' ))[0] ),
        -temp_low => Weather::Bug::Temperature->from_xml( ($w->findnodes( 'aws:temp-low' ))[0] ),
        -temp_rate => Weather::Bug::Temperature->from_xml( ($w->findnodes( 'aws:temp-rate' ))[0] ),

        -sunrise => _parse_datetime( ($w->findnodes( 'aws:sunrise' ))[0] ),
        -sunset => _parse_datetime( ($w->findnodes( 'aws:sunset' ))[0] ),

        -wetbulb => Weather::Bug::Temperature->from_xml( ($w->findnodes( 'aws:wet-bulb' ))[0] ),

        -wind_speed => Weather::Bug::Quantity->from_xml( ($w->findnodes( 'aws:wind-speed' ))[0] ),
        -wind_speed_avg => Weather::Bug::Quantity->from_xml( ($w->findnodes( 'aws:wind-speed-avg' ))[0] ),
        -wind_dir => $w->findvalue( 'aws:wind-direction' ),
        -wind_dir_avg => $w->findvalue( 'aws:wind-direction-avg' ),
    );
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Weather::Bug::Weather - Simple class interface for a weather report.

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

The Weather class wraps the concept of a WeatherBug weather report.
The WeatherBug API provides two different weather reports: Live Compact, and Live.
This object wraps the full form which contains the basic information you may
want from a weather observation plus detailed information and some summary
information.

=head1 INTERFACE 

The Weather interface provides a factory method that constructs the
object from an XML node. It also provides accessor methods for the various
pieces of data comprising the weather observation.

=head2 Factory Methods

Since the Weather object will almost always be created from an XML stream,
this class provides a method for constructing a Weather object from the XML
responses.

=over 4

=item from_xml

Extract the weather information from an C<aws:obs> node, such as the
ones returned by the I<getLiveWeather> WeatherBug request. 

$bug - the L<Weather::Bug> object
$w - the C<aws:obs> XML node
$creator - either a L<Weather::Bug::Station> or a C<Weather::Bug> object.

If we get a Station, use it internally, otherwise we need to parse the
XML to create a station object.

Return a new L<Weather::Bug::Weather> object. Dies on failure.

=back

=head2 Accessor Methods

The Station object provides accessor methods for the following fields:

=over 4

=item date

A L<DateTime> object representing the time of the observation.

=item station

A L<Weather::Bug::Station> object representing the location of the observation.

=item aux_temp

A L<Weather::Bug::Temperature> object representing the auxillary temperature.

=item aux_temp_rate

A L<Weather::Bug::Temperature> object representing rate of change of the auxillary
temperature.

=item dew_point

A L<Weather::Bug::Temperature> object representing the current dew point.

=item elevation

A L<Weather::Bug::Quantity> object representing the elevation of the WeatherBug
station.

=item feels_like

A L<Weather::Bug::Temperature> object representing what temperature the outside
I<feels like> taking into account wind and humidity.

=item gust_time

A L<DateTime> object repesenting the time of the last recorded gust of wind.

=item gust_speed

A L<Weather::Bug::Quantity> object representing the speed of the last recorded
wind gust.

=item gust_dir

A string representing the direction of the last wind gust.

=item humidity

A L<Weather::Bug::Quantity> object representing the current humidity.

=item humidity_high

A L<Weather::Bug::Quantity> object representing the high humidity for today.

=item humidity_low

A L<Weather::Bug::Quantity> object representing the low humidity for today.

=item humidity_rate

A float representing the current change in humidity.

=item indoor_temp

A L<Weather::Bug::Temperature> object representing the indoor temperature at the
site of the WeatherBug station.

=item indoor_temp_rate

A L<Weather::Bug::Temperature> object representing the rate at which the indoor
temperature at the site of the WeatherBug station is changing.

=item light

A float representing the current light level.

=item light_rate

A float representing the current change in light level.

=item moon_phase

A integer representing the current phase of the moon.

=item moon_phase_img

A URL pointing to an image representing the current moon phase.

=item pressure

A L<Weather::Bug::Quantity> object representing the current barometric pressure.

=item pressure_high

A L<Weather::Bug::Quantity> object representing the high barometric pressure for
today.

=item pressure_low

A L<Weather::Bug::Quantity> object representing the low barometric pressure for
today.

=item pressure_rate

A float representing the current change in barometric pressure.

=item rain_month

A L<Weather::Bug::Quantity> object representing the amount of rain that has fallen
this month.

=item rain_rate

A L<Weather::Bug::Quantity> object representing the amount of rain that has fallen
is falling per hour.

=item rain_rate_max

A L<Weather::Bug::Quantity> object representing the maximum amount of rain that has fallen
was falling per hour.

=item rain_today

A L<Weather::Bug::Quantity> object representing the amount of rain that has fallen
this today.

=item rain_year

A L<Weather::Bug::Quantity> object representing the amount of rain that has fallen
this year.

=item temp

A L<Weather::Bug::Temperature> object representing the current outdoor temperature.

=item temp_high

A L<Weather::Bug::Temperature> object representing the high temperature for today.

=item temp_low

A L<Weather::Bug::Temperature> object representing the low temperature for today.

=item temp_rate

A L<Weather::Bug::Temperature> object representing the change in temperature at the
current time.

=item sunrise

A L<DateTime> object representing the time for today's sunrise.

=item sunset

A L<DateTime> object representing the time for today's sunset.

=item wet_bulb

A L<Weather::Bug::Temperature> object representing the current wet-bulb temperature.

=item wind_speed

A L<Weather::Bug::Quantity> object representing the current wind speed.

=item wind_speed_avg

A L<Weather::Bug::Quantity> object representing the average wind speed.

=item wind_dir

A string representing the direction of the current prevailing wind.

=item wind_dir_avg

A string representing the average direction of the prevailing wind.

=back

=head1 DIAGNOSTICS

=over

=item C<< Unable to create a Station localizing the Weather. >>

The from_xml method is either not passed a L<Weather::Bug> or L<Weather::Bug::Station>
object, or we are unable to build a Station object.

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
