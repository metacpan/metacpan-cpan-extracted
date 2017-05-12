package Weather::Bug::SevenDayForecast;

use warnings;
use strict;
use Moose;
use XML::LibXML;
use Weather::Bug::Location;
use Weather::Bug::Forecast;
use DateTime;
use Weather::Bug::DateParser;

our $VERSION = '0.25';

has 'type' => ( is => 'ro', isa => 'Str', init_arg => '-type' );
has 'date' => ( is => 'ro', isa => 'DateTime', init_arg => '-date' );
has 'location' => ( is => 'ro', isa => 'Weather::Bug::Location', init_arg => '-loc' );
has 'forecasts' => ( is => 'ro', isa => 'ArrayRef[Weather::Bug::Forecast]', init_arg => '-forecasts' );

sub _parse_date
{
    my $date_str = shift;

    my $d = eval {
        my $p = Weather::Bug::DateParser->new();
        $p->parse_datetime( $date_str );
    };
    die "Date string is not formatted as expected.\n" if $@;
    return $d;
}

sub from_xml
{
    my $class = shift;
    my $node = shift;

    return Weather::Bug::SevenDayForecast->new(
        -type => $node->findvalue( '@type' ),
        -date => _parse_date( $node->findvalue( '@date' ) ),
        -loc => Weather::Bug::Location->from_forecast( ($node->findnodes( "aws:location" ))[0] ),
        -forecasts => _parse_forecast_list( $node->findnodes( 'aws:forecast' ) ),
    );
}

sub _parse_forecast_list
{
    my @fcnodes = @_;
    my @forecasts = ();

    die "No 'aws:forecast' nodes found.\n" unless @fcnodes;

    foreach my $fcast (@fcnodes)
    {
        push @forecasts,
             Weather::Bug::Forecast->from_xml( $fcast );
    }
    return \@forecasts;
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Weather::Bug::SevenDayForecast - Simple class interface to the 7 day forecast.

=head1 VERSION

This document describes Weather::Bug::SevenDayForecast version 0.25

=head1 SYNOPSIS

    use Weather::Bug;

    my $wbug = Weather::Bug->new( 'YOURAPIKEYHERE' );
    my $fc = $wbug->get_forecast( 77096 );

    printf( "Forecast for \%s, \%s at \%s, on \%s\n",
            $fc->location()->city(), $fc->location()->state(),
            $fc->date()->hms(), $fc->date->ymd()
    );
    foreach my $f ($fc->forecasts())
    {
        my $hi = $f->high();
        my $lo = $f->low();

        print $f->title(), ":\n",
              ($hi->is_null() ? "" : "\tHigh: $hi\n"), 
              ($lo->is_null() ? "" : "\tLow: $lo\n"),
              $f->prediction(), "\n";
    }

=head1 DESCRIPTION

The SevenDayForecast object encapsulates the time/date, location, and
a set of Forecast objects that represents a 7-day forecast response
from the WeatherBug API.

=head1 INTERFACE 

=head2 Accessor Methods

The methods providing access to the SevenDayForecast's fields are:

=over 4

=item date

Date of the forecast as a DateTime object.

=item type

The type of forecast, always appears to be I<detailed>.

=item location

A Location object describing where the forecast is made.

=item forecasts

Reference to an array of Weather::Bug::Forecast objects. The items
are ordered in time.

=back

=head2 Factory Methods

Since the object is usually created from an XML repsonse, the class provides
factory methods that take a portion of the XML and return a SevenDayForecast.

=over 4

=item from_xml

This class method takes an L<XML::LibXML> Node object representing an
C<aws:forecasts> node and returns a Weather::Bug::SevenDayForecast object.

=back

=head1 DIAGNOSTICS

=over 4

=item C<< No '%s' node found. >>

An XML node of the specified type was not found.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Weather::Bug requires no configuration files or environment variables.

=head1 DEPENDENCIES

C<Moose>, C<XML::LibXML>, and C<DateTime>.

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
