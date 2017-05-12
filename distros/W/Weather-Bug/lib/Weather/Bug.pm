package Weather::Bug;

use warnings;
use strict;
use Moose;
use LWP::Simple;
use XML::LibXML;
use Weather::Bug::Station;
use Weather::Bug::SevenDayForecast;
use Weather::Bug::Alert;

our $VERSION = '0.25';

has 'licensekey' => ( is => 'ro', isa => 'Str', init_arg => '-key', required => 1 );

# This can be overridden in the child test class
sub _get {
  my $self = shift;
  my $url = shift;
  return LWP::Simple::get( $url );
}

sub list_stations
{
    my $self = shift;
    my $zipcode = shift; # might want to validate.

    my $response = $self->request( 'getStations', { zipcode => $zipcode } );

    my $p = XML::LibXML->new();
    my $doc = $p->parse_string( $response );
    die "Unable to parse output from 'getStations' request.\n" unless defined $doc;

    my @stations = ();
    foreach my $node ($doc->findnodes( "//aws:station" ))
    {
        my $station = Weather::Bug::Station->from_xml(
            $self, $node
        );
        push @stations, $station;
    }

    return @stations;
}

sub request
{
    my $self = shift;
    my $cmd = shift;
    my $parms = shift;

    my $url = "http://$self->{licensekey}.api.wxbug.net/$cmd.aspx?acode=$self->{licensekey}";
    foreach my $p (keys %{$parms})
    {
        $url .= "&$p=$parms->{$p}";
    }

    my $output = $self->_get( $url );
    die "Request for '$cmd' failed.\n" unless defined $output;
    return $output;
}

sub get_forecast
{
    my $self = shift;
    my $zipcode = shift;

    my $response = $self->request( 'getFullForecast', { zipcode => $zipcode } );

    my $p = XML::LibXML->new();
    my $doc = $p->parse_string( $response );
    die "Unable to parse output from 'getFullForecast' request.\n" unless defined $doc;

    my ($f) = $doc->findnodes( "//aws:forecasts" );
    die "No 'aws:forecasts' node found.\n" unless defined $f;

    return Weather::Bug::SevenDayForecast->from_xml( $f );
}

sub get_alerts
{
    my $self = shift;
    my $zipcode = shift;

    my $response = $self->request( 'getalerts', { zipcode => $zipcode } );

    my $p = XML::LibXML->new();
    my $doc = $p->parse_string( $response );
    die "Unable to parse output from 'getalerts' request.\n" unless defined $doc;

    my @alerts = ();
    foreach my $node ($doc->findnodes( "//aws:alert" ))
    {
        my $alert = Weather::Bug::Alert->from_xml( $node );
        push @alerts, $alert;
    }

    return @alerts;
}

sub get_live_compact_weather
{
    my $self = shift;
    my $id = shift;
    my $zipcode = shift;

    my $response = $self->request(
        'getLiveCompactWeather',
        { zipcode => $zipcode, StationID => $id }
    );

    my $p = XML::LibXML->new();
    my $doc = $p->parse_string( $response );
    die "Unable to parse output from 'getLiveCompactWeather' request.\n" unless defined $doc;

    my ($w) = $doc->findnodes( "//aws:weather" );
    die "No 'aws:weather' node found.\n" unless defined $w;
    return Weather::Bug::CompactWeather->from_xml(
        $w, $self
    );
}

sub get_live_weather
{
    my $self = shift;
    my $id = shift;
    my $zipcode = shift;

    my $response = $self->request(
        'getLiveWeather',
        { zipcode => $zipcode, StationID => $id }
    );

    my $p = XML::LibXML->new();
    my $doc = $p->parse_string( $response );
    die "Unable to parse output from 'getLiveWeather' request.\n" unless defined $doc;

    my ($ob) = $doc->findnodes( "//aws:ob" );
    return Weather::Bug::Weather->from_xml( $ob, $self );
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Weather::Bug - Provide an object oriented interface to the WeatherBug API.


=head1 VERSION

This document describes Weather::Bug version 0.25


=head1 SYNOPSIS

    use Weather::Bug;

    my $wxbug = Weather::Bug->new( -key => 'YOURKEYHERE' );
  
=head1 DESCRIPTION

The Weather::Bug module provides an object-oriented wrapper around
the WeatherBug web API. An object of this class performs requests and parses
the output to provide an easier interface for retrieving weather information.

Use of this module requires registering with WeatherBug to acquire a license
key. This key provides a developer with access to the API.

=head1 INTERFACE

The module supports several methods that access the WeatherBug API. In
addition, the module supports a few convenience methods that simplify
access to the underlying functionality by other classes.

The object is created using the C<new> class method. It takes a single
required named parameter B<-key>, whose value is the license key you obtained
from WeatherBug.

The constructor also supports an optional parameter B<-getsub> whose value
is a C<coderef> that works as a standin for L<LWP::Simple::get>. This is useful
for testing, or if you need to get your data from somewhere other than an
HTTP request.

=head2 WeatherBug API Methods

These methods provide high-level access to the WeatherBug API.

=over 4

=item list_stations

This method takes one parameter, a US I<zipcode> giving a start location
to look for WeatherBug stations. The method returns a list of
L<Weather::Bug::Station> objects representing the stations near the
requested location. The definition of I<near> and the number of stations
returned depends on the density of stations in the area of interest.

On failure, the method returns an empty list.

=item get_forecast

Retrieve the 7-day forecast for the supplied I<zipcode> as a
L<Weather::Bug::SevenDayForecast> object.

On failure, the method returns C<undef>.

=item get_alerts

This method takes one parameter, a US I<zipcode> giving a location to check
for alerts. The method returns a list of L<Weather::Bug::Alert> objects
representing alerts that apply at the current time.

If there are no alerts, the method returns an empty list.

=item get_live_compact_weather

This method requires two named parameters: I<zipcode> and I<StationID>. The
method provides access to what WeatherBug refers to as I<Live Compact Weather>
as a L<Weather::Bug::CompactWeather> object.

=item get_live_weather

This method requires two named parameters: I<zipcode> and I<StationID>. The
method provides access to what WeatherBug refers to as I<Live Weather> as a
L<Weather::Bug::Weather> object.

=back

=head2 Convenience Methods

These utility methods are used by some of the other Weather::Bug
classes to do their work. Some of these methods may be used for lower-level
access to the WeatherBug API.

=over 4

=item request

This method takes two parameters, a C<cmd> name and a hash containing
parameters to pass to the command.

The C<cmd> parameter is the filename used in the URL for that API method,
without the extension. Supported commands are:

=over 4

=item getStations

=item getFullForecast

=item getLiveWeather

=item getLiveCompactWeather

=item getalerts

=back

This allows an extension point in the class. If WeatherBug extends their
API, this method can be used to make a call in the same way as any of the
other methods.

Using this method, the URL is created mostly automatically including the
hostname, the file extension, and the I<acode> parameter supplying the
license key.

On success, the method returns the body of the response as a string. On
failure, the method C<die>s.

=back

=head1 DIAGNOSTICS

This section lists error messages that this module may display.

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

This module depends on C<Moose>, C<LWP::Simple>, and C<XML::LibXML>.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-weather-weatherbug@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 ACKNOWLEDGEMENTS

The following people have contributed to this module.

=over 4

=item * Joseph Hull

=item * Gordon Child

=back

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
