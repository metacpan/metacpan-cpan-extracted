package Weather::OpenWeatherMap::Request::Forecast;
$Weather::OpenWeatherMap::Request::Forecast::VERSION = '0.005004';
use URI::Escape 'uri_escape_utf8';
use Types::Standard -all;

use Moo;
extends 'Weather::OpenWeatherMap::Request';

has hourly => (
  lazy      => 1,
  is        => 'ro',
  isa       => Bool,
  builder   => sub { 0 },
);

has days => (
  lazy      => 1,
  is        => 'ro',
  isa       => Int,
  builder   => sub { 7 },
);


sub _url_bycode {
  my ($self, $code) = @_;
  'http://api.openweathermap.org/data/2.5/forecast/'
    . ($self->hourly ? '' : 'daily')
    . '?id=' . uri_escape_utf8($code)
    . '&units=' . $self->_units
    . '&cnt='   . $self->days
}

sub _url_bycoord {
  my $self = shift;
  my ($lat, $long) = map {; uri_escape_utf8($_) } @_;
  'http://api.openweathermap.org/data/2.5/forecast/'
    . ($self->hourly ? '' : 'daily')
    . "?lat=${lat}&lon=${long}"
    . '&units=' . $self->_units
    . '&cnt='   . $self->days
}

sub _url_byname {
  my ($self, @parts) = @_;
  'http://api.openweathermap.org/data/2.5/forecast/'
    . ($self->hourly ? '' : 'daily')
    . '?q=' . join(',', map {; uri_escape_utf8($_) } @parts)
    . '&units=' . $self->_units
    . '&cnt='   . $self->days
}


1;

=pod

=head1 NAME

Weather::OpenWeatherMap::Request::Forecast

=head1 SYNOPSIS

  # Usually created by Weather::OpenWeatherMap

=head1 DESCRIPTION

A L<Weather::OpenWeatherMap::Request> subclass for building a forecast
request.

=head2 ATTRIBUTES

=head3 days

The number of days to ask for (up to 16 for daily reports; up to 5 if
L</hourly> is true).

=head3 hourly

Request an hourly (actually 3-hour blocks) forecast.

By default, a daily report is requested.

=head1 SEE ALSO

L<Weather::OpenWeatherMap::Request>

L<Weather::OpenWeatherMap::Result>

L<Weather::OpenWeatherMap::Result::Forecast>

L<Weather::OpenWeatherMap>

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

Licensed under the same terms as Perl.

=cut
