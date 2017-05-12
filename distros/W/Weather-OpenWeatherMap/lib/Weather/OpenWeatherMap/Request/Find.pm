package Weather::OpenWeatherMap::Request::Find;
$Weather::OpenWeatherMap::Request::Find::VERSION = '0.005004';
use Carp;
use URI::Escape 'uri_escape_utf8';
use Types::Standard -all;

use Weather::OpenWeatherMap::Error;

use Moo;
extends 'Weather::OpenWeatherMap::Request';

# FIXME um, is any of this still correct?
#  ... OWM docs do not say much anymore ...

has max => (
  lazy      => 1,
  is        => 'ro',
  isa       => Int,
  builder   => sub { 10 },
);

has type => (
  lazy      => 1,
  is        => 'ro',
  isa       => Str,
  builder   => sub { 'accurate' },
);


sub _url_bycode {
  my ($self) = @_;
  die Weather::OpenWeatherMap::Error->new(
    request => $self,
    source  => 'internal',
    status  => 'Find requests do not support city codes',
  )
}

sub _url_bycoord {
  my $self = shift;
  my ($lat, $long) = map {; uri_escape_utf8($_) } @_;
  "http://api.openweathermap.org/data/2.5/find?lat=$lat&lon=$long"
    . '&units=' . $self->_units
    . '&type='  . $self->type
    . '&cnt='   . $self->max
}

sub _url_byname {
  my ($self, @parts) = @_;
  'http://api.openweathermap.org/data/2.5/find?q='
    . join(',', map {; uri_escape_utf8($_) } @parts)
    . '&units=' . $self->_units
    . '&type='  . $self->type
    . '&cnt='   . $self->max
}

1;

=head1 NAME

Weather::OpenWeatherMap::Request::Find

=head1 SYNOPSIS

  # Usually created by Weather::OpenWeatherMap
  use Weather::OpenWeatherMap::Request::Find;
  my $request = Weather::OpenWeatherMap::Request::Find->new(
    tag       => 'foo',
    location  => 'Manchester',
    max       => 5,
  );

  my $http_request_obj = $request->http_request;

=head1 DESCRIPTION

A L<Weather::OpenWeatherMap::Request> subclass for building a city search
request.

=head1 ATTRIBUTES

=head3 max

The maximum number of results to ask for.

=head3 type

The type of search to perform; C<accurate> looks for exact matches, C<like>
searches by substring.

=head1 SEE ALSO

L<http://www.openweathermap.org/current>

L<Weather::OpenWeatherMap::Result::Find>

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

Licensed under the same terms as Perl.
