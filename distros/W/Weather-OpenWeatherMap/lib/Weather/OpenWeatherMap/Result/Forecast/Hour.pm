package Weather::OpenWeatherMap::Result::Forecast::Hour;
$Weather::OpenWeatherMap::Result::Forecast::Hour::VERSION = '0.005004';
use strictures 2;

use Types::Standard      -all;
use Types::DateTime      -all;
use List::Objects::Types -all;

use Weather::OpenWeatherMap::Units -all;


use Moo;

has dt_txt => (
  lazy        => 1,
  is          => 'ro',
  isa         => Str,
  builder     => sub { '' }, 
);

has _main => (
  init_arg    => 'main',
  required    => 1,
  is          => 'ro',
  isa         => HashObj,
  coerce      => 1,
);

has temp_f => (
  lazy      => 1,
  is        => 'ro',
  isa       => CoercedInt,
  coerce    => 1,
  builder   => sub { shift->_main->{temp} },
);
sub temp { shift->temp_f }

has temp_c => (
  lazy      => 1,
  is        => 'ro',
  isa       => CoercedInt,
  coerce    => 1,
  builder   => sub { f_to_c shift->temp },
);

has humidity => (
  lazy      => 1,
  is        => 'ro',
  isa       => CoercedInt,
  coerce    => 1,
  builder   => sub { shift->_main->{humidity} },
);

has pressure => (
  lazy      => 1,
  is        => 'ro',
  isa       => StrictNum,
  coerce    => 1,
  builder   => sub { shift->_main->{pressure} },
);

has _wind => (
  init_arg    => 'wind',
  lazy        => 1,
  is          => 'ro',
  isa         => HashObj,
  coerce      => 1,
  builder     => sub { +{ speed => 0, deg => 0 } },
);

has wind_speed_mph => (
  lazy        => 1,
  is          => 'ro',
  isa         => CoercedInt,
  coerce      => 1,
  builder     => sub { shift->_wind->{speed} // 0 },
);

has wind_speed_kph => (
  lazy        => 1,
  is          => 'ro',
  isa         => CoercedInt,
  coerce      => 1,
  builder     => sub { mph_to_kph shift->wind_speed_mph },
);

has wind_direction => (
  lazy        => 1,
  is          => 'ro',
  isa         => Str,
  builder     => sub { deg_to_compass shift->wind_direction_degrees },
);

has wind_direction_degrees => (
  lazy        => 1,
  is          => 'ro',
  isa         => CoercedInt,
  coerce      => 1,
  builder     => sub { shift->_wind->{deg} // 0 },
);

has _clouds => (
  init_arg    => 'clouds',
  lazy        => 1,
  is          => 'ro',
  isa         => HashObj,
  coerce      => 1,
  builder     => sub { +{ all => 0 } },
);

sub cloud_coverage { shift->_clouds->{all} // 0 }

has _snow => (
  init_arg    => 'snow',
  lazy        => 1,
  is          => 'ro',
  isa         => HashObj,
  coerce      => 1,
  builder     => sub { +{ '3h' => 0 } },
);

sub snow { 0 + sprintf '%.1f', shift->_snow->{'3h'} // 0 }

has _rain => (
  init_arg    => 'rain',
  lazy        => 1,
  is          => 'ro',
  isa         => HashObj,
  coerce      => 1,
  builder     => sub { +{ '3h' => 0 } },
);

sub rain { 0 + sprintf '%.1f', shift->_rain->{'3h'} // 0 }


with 'Weather::OpenWeatherMap::Result::Forecast::Block';


1;

=pod

=head1 NAME

Weather::OpenWeatherMap::Result::Forecast::Hour - Weather report for a 3hr block

=head1 SYNOPSIS

  # Usually retrieved via a Weather::OpenWeatherMap::Result::Forecast

=head1 DESCRIPTION

A L<Weather::OpenWeatherMap> weather forecast for a 3-hr block, provided by a
L<Weather::OpenWeatherMap::Result::Forecast> hourly weather report.

This class consumes L<Weather::OpenWeatherMap::Result::Forecast::Block>; look
there for other applicable methods and attributes.

=head2 ATTRIBUTES

=head3 dt_txt

A textual representation of the date/time (UTC) for this forecast block, as
provided by the OpenWeatherMap service.

See also: L<Weather::OpenWeatherMap::Result::Forecast::Block/dt>

=head3 temp_f

The predicted temperature (in Fahrenheit).

=head3 temp_c

The predicted temperature (in Celsius).

=head3 snow

The predicted amount of snow (in mm), if applicable.

=head3 rain

The predicted amount of rain (in mm), if applicable.

=head1 SEE ALSO

L<http://www.openweathermap.org/forecast5>

L<Weather::OpenWeatherMap::Result>

L<Weather::OpenWeatherMap::Result::Forecast>

L<Weather::OpenWeatherMap::Result::Forecast::Block>

L<Weather::OpenWeatherMap::Result::Forecast::Day>

L<Weather::OpenWeatherMap::Result::Current>

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut


