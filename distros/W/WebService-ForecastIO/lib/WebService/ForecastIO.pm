use 5.014;

package WebService::ForecastIO;
$WebService::ForecastIO::VERSION = '0.02';
use Moo;
with 'WebService::ForecastIO::Request';

use Time::Piece;

# ABSTRACT: Perl client for api.forecast.io


has 'units' => (
    is => 'ro',
);


has 'exclude' => (
    is => 'ro',
);


sub to_timepiece {
    my ($self, $epoch_secs) = @_;

    return Time::Piece->new($epoch_secs);
}


sub parse_datetime {
    my ($self, $iso8601) = @_;

    return Time::Piece->strptime($iso8601, "%Y-%m-%dT%H:%M:%S");
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::ForecastIO - Perl client for api.forecast.io

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    use 5.014;

    my $forecast = WebService::ForecastIO->new(
            api_key => 'secret',
            units => 'si', # metric units
            exclude => 'hourly,minutely,currently,flags', # get 7 day forecast only
    );

    #                             latitude          longitude
    my $json = $forecast->request(29.7492738082192, -95.4709680410959);

    # Human readable summary of daily data
    say $json->{daily}->{summary};

=head1 OVERVIEW

This is a Perl client for L<forecast.io API|https://developer.forecast.io>. Forecast.io 
applies "big data" analysis techniques to publicly available weather data including 
radar image analysis.  One of the things it attempts to predict is I<when> certain
weather events like rain will start, and the duration of those events.

This library requires an API key which can be obtained for free from the 
L<developer web site|https://developer.forecast.io>. The first 1,000 calls
per day are allowed without charge.  (More calls can be made if payment arrangements
are made.)

See the L<API docs|https://developer.forecast.io/docs/v2> for full details about
what data is provided and what granularity data sets are offered.

B<NOTE>: Errors are fatal. Please use something like L<Try::Tiny> if you
want to handle errors some other way.

=head1 ATTRIBUTES

=head2 units

This attribute overrides the default units of C<us>. Available units are:

=over

=item * C<si>

Metric units (windspeed in meters/second)

=item * C<ca>

Metric units, except windspeed in km/h

=item * C<uk>

Metric units, except windspeed in mi/h

=item * C<auto>

Unit selection based on request IP geolocation

=back

=head2 exclude

A comma delimited list of data sets to exclude. Choices are:

C<minutely>, C<currently>, C<hourly>, C<daily>, C<alerts>, C<flags>

See the API docs for information about what these data blocks represent.

Spaces should be omitted between exclusions.

=head2 api_key

Holds the API key for the forecast.io service.

=head1 METHODS

=head2 request

This method takes two or three parameters.

The first two parameters are C<latitude> and C<longitude> expressed
as floats. The optional third parameter is a C<time> value. The time
value can be expressed as either epoch seconds or as an iso8601
format time. 

Data sets up to 60 years old are available. (Such times should
be expressed as iso8601 format times since epoch seconds start
at midnight, January 1, 1970.)

=head2 to_timepiece

A convenience method that takes epoch seconds and returns a
new L<Time::Piece> object.  You can stringify this object to
iso8601 format by calling the C<datetime()> method on it.

=head2 parse_datetime

A convenience method that takes an iso8601 formatted string
and returns a new L<Time::Piece> object. This object can output
epoch seconds by calling the C<epoch()> method on it.

=head1 SEE ALSO

=over

=item * L<WebService::ForecastIO::Request>

=item * L<API docs|https://developer.forecast.io/docs/v2>

=back

=head1 AUTHOR

Mark Allen <mrallen1@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Mark Allen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
