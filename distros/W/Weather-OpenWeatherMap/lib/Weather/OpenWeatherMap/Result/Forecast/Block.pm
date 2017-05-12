package Weather::OpenWeatherMap::Result::Forecast::Block;
$Weather::OpenWeatherMap::Result::Forecast::Block::VERSION = '0.005004';
use strictures 2;

use Types::Standard       -all;
use Types::DateTime       -all;
use List::Objects::Types  -all;

use Weather::OpenWeatherMap::Units -all;


use Moo::Role;

use Storable 'freeze';

requires qw/
  cloud_coverage
  humidity
  pressure
  wind_speed_mph
  wind_speed_kph
  wind_direction
  wind_direction_degrees
/;

has dt => (
  is        => 'ro',
  isa       => DateTimeUTC,
  coerce    => 1,
  builder   => sub { 0 },
);

has _weather_list => (
  init_arg  => 'weather',
  is        => 'ro',
  isa       => ArrayObj,
  coerce    => 1,
  builder   => sub { [] },
);

has _first_weather_item => (
  lazy      => 1,
  is        => 'ro',
  isa       => HashRef,
  builder   => sub { shift->_weather_list->[0] || +{} },
);


has conditions_terse => (
  lazy      => 1,
  is        => 'ro',
  isa       => Str,
  builder   => sub { shift->_first_weather_item->{main} // '' },
);

has conditions_verbose => (
  lazy      => 1,
  is        => 'ro',
  isa       => Str,
  builder   => sub { shift->_first_weather_item->{description} // '' },
);

has conditions_code => (
  lazy      => 1,
  is        => 'ro',
  isa       => Int,
  builder   => sub { shift->_first_weather_item->{id} // 0 },
);

has conditions_icon => (
  lazy      => 1,
  is        => 'ro',
  isa       => Maybe[Str],
  builder   => sub { shift->_first_weather_item->{icon} },
);

1;

=pod

=head1 NAME

Weather::OpenWeatherMap::Result::Forecast::Block - A Role for weather forecast items

=head1 SYNOPSIS

  # A Role providing attributes/methods for objects produced by a
  # Weather::OpenWeatherMap::Result::Forecast, one of:
  #  Weather::OpenWeatherMap::Result::Forecast::Day
  #  Weather::OpenWeatherMap::Result::Forecast::Hour

=head1 DESCRIPTION

This role provides methods and attributes for classes implementing a
L<Weather::OpenWeatherMap> weather forecast for a block of time, such as
L<Weather::OpenWeatherMap::Result::Forecast::Day> &
L<Weather::OpenWeatherMap::Result::Forecast::Hour>.

=head2 ATTRIBUTES

=head3 cloud_coverage

The forecast cloud coverage as a percentage.

=head3 conditions_terse

The conditions category.

=head3 conditions_verbose

The conditions description string.

=head3 conditions_code

The L<OpenWeatherMap|http://www.openweathermap.org/> conditions code.

=head3 conditions_icon

The L<OpenWeatherMap|http://www.openweathermap.org/> conditions icon.

=head3 dt

  my $date = $result->dt->mdy;

A L<DateTime> object coerced from the timestamp (in UTC) attached to this
forecast.

=head3 humidity

The forecast humidity as a percentage.

=head3 pressure

The forecast atmospheric pressure in hPa.

=head3 wind_speed_mph

The forecast wind speed in MPH.

=head3 wind_speed_kph

The forecast wind speed in KPH.

=head3 wind_direction

The forecast wind direction as a (inter-)cardinal direction in the set
C<< [ N NNE NE ENE E ESE SE SSE S SSW SW WSW W WNW NW NNW ] >>

=head3 wind_direction_degrees

The forecast wind direction in degrees azimuth.

=head1 SEE ALSO

L<Weather::OpenWeatherMap::Result>

L<Weather::OpenWeatherMap::Result::Forecast>

L<Weather::OpenWeatherMap::Result::Forecast::Day>

L<Weather::OpenWeatherMap::Result::Forecast::Hour>

L<Weather::OpenWeatherMap::Result::Current>

L<http://www.openweathermap.org>

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
