package Weather::Bug::Forecast;

use warnings;
use strict;
use Moose;
use XML::LibXML;
use Weather::Bug::Temperature;

our $VERSION = '0.25';

has 'title' => ( is => 'ro', isa => 'Str', init_arg => '-title' );
has 'short_title' => ( is => 'ro', isa => 'Str', init_arg => '-short' );
has 'imageurl' => ( is => 'ro', isa => 'Str', init_arg => '-image' );
has 'description' => ( is => 'ro', isa => 'Str', init_arg => '-desc' );
has 'prediction' => ( is => 'ro', isa => 'Str', init_arg => '-pred' );
has 'high' => ( is => 'ro', isa => 'Weather::Bug::Temperature', init_arg => '-high' );
has 'low' => ( is => 'ro', isa => 'Weather::Bug::Temperature', init_arg => '-low' );

sub from_xml
{
    my $class = shift;
    my $node = shift;

    my ($hi) = $node->findnodes( 'aws:high' );
    my ($lo) = $node->findnodes( 'aws:low' );

    die "No 'aws:high' node found.\n" unless defined $hi;
    die "No 'aws:low' node found.\n" unless defined $lo;

    return Weather::Bug::Forecast->new(
        -title => $node->findvalue( 'aws:title' ),
        -short => $node->findvalue( 'aws:short-title' ),
        -image => $node->findvalue( 'aws:image' ),
        -desc => $node->findvalue( 'aws:description' ),
        -pred => $node->findvalue( 'aws:prediction' ),
        -high => Weather::Bug::Temperature->from_xml( $hi ),
        -low => Weather::Bug::Temperature->from_xml( $lo ),
    );
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Weather::Bug::Forecast - Simple class interface to a single forecast from
the WeatherBug API.

=head1 VERSION

This document describes Weather::Bug::Forecast version 0.25

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

This object encapsulates a single Forecast from the 7-day forecast response
from the WeatherBug API. A FullForecast object contains a list of Forecast
objects, each of which describes one forecast.

=head1 INTERFACE 

=head2 Accessor Methods

The methods providing access to the location's fields are:

=over 4

=item title

String explaining the time period of the forecast.

=item short_title

A short version of the prediction containing just the most important
information.

=item imageurl

URL of an image characterizing the forecast.

=item description

Effectively the same information as the I<title>, sometimes abbreviated.

=item prediction

Text prediction of the weather for the time period.

=item high

High temperature for the time period.

=item low

Low temperature for the time period.

=back

=head2 Factory Method

Since the object is usually created from an XML repsonse, the class provides
factory methods that take a portion of the XML and return a Forecast object.

=over 4

=item from_xml

Extract the Forecast information from an C<aws:forecast> node

=over 4

=item $bug

the Weather::Bug object

=item $node

the aws:station XML node

=back

Return a new Weather::Bug::Forecast object

=back

=head1 DIAGNOSTICS

None.

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
