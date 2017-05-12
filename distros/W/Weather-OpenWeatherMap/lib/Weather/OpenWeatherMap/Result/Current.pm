package Weather::OpenWeatherMap::Result::Current;
$Weather::OpenWeatherMap::Result::Current::VERSION = '0.005004';
use strictures 2;
use Carp;

use List::Objects::Types -all;
use Types::Standard      -all;
use Types::DateTime      -all;

use Weather::OpenWeatherMap::Units qw/
  f_to_c
  mph_to_kph
  deg_to_compass
/;


=pod

=for Pod::Coverage lazy_for

=cut

sub lazy_for {
  my $type = shift;
  ( 
    lazy => 1, is => 'ro', isa => $type, 
    ( $type->has_coercion ? (coerce => 1) : () ), 
    @_ 
  )
}


use Moo; 
extends 'Weather::OpenWeatherMap::Result';


has dt => ( lazy_for DateTimeUTC,
  builder   => sub { shift->data->{dt} },
);

has id   => ( lazy_for Int,
  builder   => sub { shift->data->{id} },
);

has name => ( lazy_for Str,
  builder   => sub { shift->data->{name} },
);

has country => ( lazy_for Str,
  builder   => sub { shift->data->{sys}->{country} // '' },
);

has station => ( lazy_for Str,
  builder   => sub { shift->data->{base} // '' },
);


has latitude => ( lazy_for StrictNum,
  builder   => sub { shift->data->{coord}->{lat} },
);

has longitude => ( lazy_for StrictNum,
  builder   => sub { shift->data->{coord}->{lon} },
);


has temp_f => ( lazy_for Int,
  builder   => sub { int( shift->data->{main}->{temp} ) },
);
sub temp { shift->temp_f }

has temp_c => ( lazy_for Int,
  builder   => sub { int f_to_c( shift->temp_f ) },
);


has humidity => ( lazy_for Int,
  builder   => sub { int( shift->data->{main}->{humidity} // 0 ) },
);

has pressure => ( lazy_for StrictNum,
  builder   => sub { shift->data->{main}->{pressure} },
);

has cloud_coverage => ( lazy_for Int,
  builder   => sub { int( shift->data->{clouds}->{all} // 0 ) },
);


has sunrise => ( lazy_for DateTimeUTC,
  builder   => sub { shift->data->{sys}->{sunrise} // 0 },
);

has sunset => ( lazy_for DateTimeUTC,
  builder   => sub { shift->data->{sys}->{sunset} // 0 },
);


sub _so_weather_maybe {
  my ($self) = @_;
  my $weather = $self->data->{weather};
  return unless ref $weather eq 'ARRAY' and @$weather;
  $weather->[0]
}

has conditions_terse => ( lazy_for Str,
  builder   => sub {
    my ($self) = @_;
    my $weather = $self->_so_weather_maybe || return '';
    $weather->{main} // ''
  },
);

has conditions_verbose => ( lazy_for Str,
  builder   => sub {
    my ($self) = @_;
    my $weather = $self->_so_weather_maybe || return '';
    $weather->{description} // ''
  },
);

has conditions_code => ( lazy_for Int,
  builder   => sub {
    my ($self) = @_;
    my $weather = $self->_so_weather_maybe || return 0;
    $weather->{id} // 0
  },
);

has conditions_icon => ( lazy_for Maybe[Str],
  builder   => sub {
    my ($self) = @_;
    my $weather = $self->_so_weather_maybe || return;
    $weather->{icon}
  },
);


has wind_speed_mph => ( lazy_for Int,
  builder   => sub { int( shift->data->{wind}->{speed} // 0 ) },
);

has wind_speed_kph => ( lazy_for Int,
  builder   => sub { int( mph_to_kph shift->wind_speed_mph ) },
);

has wind_direction_degrees => ( lazy_for StrictNum,
  builder   => sub { shift->data->{wind}->{deg} // 0 },
);

has wind_direction => ( lazy_for Str,
  builder   => sub { deg_to_compass( shift->wind_direction_degrees ) },
);

has wind_gust_mph => ( lazy_for Int,
  builder   => sub {
    my ($self) = @_;
    my $gust = int( $self->data->{wind}->{gust} // 0 );
    return 0 unless $gust and $gust > $self->wind_speed_mph;
    $gust
  },
);

has wind_gust_kph => ( lazy_for Int,
  builder   => sub { int( mph_to_kph shift->wind_gust_mph ) },
);

1;

=pod

=head1 NAME

Weather::OpenWeatherMap::Result::Current - Weather conditions result

=head1 SYNOPSIS

  # Normally retrieved via Weather::OpenWeatherMap

=head1 DESCRIPTION

This is a subclass of L<Weather::OpenWeatherMap::Result> containing the
result of a completed L<Weather::OpenWeatherMap::Request::Current>.

These are normally emitted by a L<Weather::OpenWeatherMap> instance.

=head2 ATTRIBUTES

=head3 Station

=head4 country

The country string.

=head4 dt

  my $reported_at = $result->dt->hms;

A UTC L<DateTime> object representing the time this report was updated.

=head4 id

The L<OpenWeatherMap|http://www.openweathermap.org/> city code.

=head4 latitude

The station's latitude.

=head4 longitude

The station's longitude.

=head4 name

The returned city name.

=head4 station

The returned station name.

=head3 Conditions

=head4 cloud_coverage

The cloud coverage as a percentage.

=head4 conditions_code

The L<OpenWeatherMap|http://www.openweathermap.org/> conditions code.[

=head4 conditions_icon

The L<OpenWeatherMap|http://www.openweathermap.org/> conditions icon.

=head4 conditions_terse

The conditions category.

=head4 conditions_verbose

The conditions description string.

=head4 humidity

Current humidity.

=head4 pressure

Atmospheric pressure in hPa.

=head4 sunrise

A UTC L<DateTime> object representing sunrise time.

(Not available for L<Weather::OpenWeatherMap::Result::Find> result items.)

=head4 sunset

A UTC L<DateTime> object representing sunset time.

(Not available for L<Weather::OpenWeatherMap::Result::Find> result items.)

=head3 Temperature

=head4 temp_f

Temperature in degrees Fahrenheit.

=head4 temp_c

Temperature in degrees Celsius.

=head3 Wind

=head4 wind_speed_mph

Wind speed in MPH.

=head4 wind_speed_kph

Wind speed in KPH.

=head4 wind_gust_mph

Wind gust speed in MPH (or 0 if the gust speed matches L</wind_speed_mph> or
is unavailable)

=head4 wind_gust_kph

Wind gust speed in KPH (or 0 if the gust speed matches L</wind_speed_kph> or
is unavailable)

=head4 wind_direction

The wind direction, as a (inter-)cardinal direction in the set
C<< [ N NNE NE ENE E ESE SE SSE S SSW SW WSW W WNW NW NNW  ] >>

=head4 wind_direction_degrees

The wind direction, in degrees azimuth.

=head1 SEE ALSO

L<http://www.openweathermap.org/current>

L<Weather::OpenWeatherMap::Result>

L<Weather::OpenWeatherMap::Result::Forecast>

L<Weather::OpenWeatherMap::Request>

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

Licensed under the same terms as Perl.

=cut
