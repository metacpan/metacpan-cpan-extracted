package Weather::OpenWeatherMap::Result::Forecast::Day;
$Weather::OpenWeatherMap::Result::Forecast::Day::VERSION = '0.005004';
use strictures 2;

use Types::Standard       -all;
use Types::DateTime       -all;
use List::Objects::Types  -all;

use Weather::OpenWeatherMap::Units -all;


use Moo; 

has cloud_coverage => (
  init_arg  => 'clouds',
  is        => 'ro',
  isa       => CoercedInt,
  coerce    => 1,
  builder   => sub { 0 },
);

has humidity => (
  is        => 'ro',
  isa       => CoercedInt,
  coerce    => 1,
  builder   => sub { 0 },
);

has pressure => (
  is        => 'ro',
  isa       => StrictNum,
  builder   => sub { 0 },
);

has wind_speed_mph => (
  init_arg  => 'speed',
  is        => 'ro',
  isa       => CoercedInt,
  coerce    => 1,
  builder   => sub { 0 },
);

has wind_speed_kph => (
  lazy      => 1,
  is        => 'ro',
  isa       => CoercedInt,
  coerce    => 1,
  builder   => sub { mph_to_kph shift->wind_speed_mph },
);

has wind_direction => (
  lazy      => 1,
  is        => 'ro',
  isa       => Str,
  builder   => sub { deg_to_compass shift->wind_direction_degrees },
);

has wind_direction_degrees => (
  init_arg  => 'deg',
  is        => 'ro',
  isa       => CoercedInt,
  coerce    => 1,
  builder   => sub { 0 },
);

{ package
    Weather::OpenWeatherMap::Result::Forecast::Day::Temps;
  use strict; use warnings FATAL => 'all';
  use Moo;
  has [qw/ morn night eve min max day /], 
    ( is => 'ro', default => sub { 0 } );
}

has temp => (
  is        => 'ro',
  isa       => (InstanceOf[__PACKAGE__.'::Temps'])
    ->plus_coercions( HashRef,
      sub { 
        Weather::OpenWeatherMap::Result::Forecast::Day::Temps->new(%$_)
      },
  ),
  coerce    => 1,
  builder   => sub {
    Weather::OpenWeatherMap::Result::Forecast::Day::Temps->new
  },
);

has temp_min_f => (
  lazy      => 1,
  is        => 'ro',
  isa       => CoercedInt,
  coerce    => 1,
  builder   => sub { shift->temp->min },
);

has temp_max_f => (
  lazy      => 1,
  is        => 'ro',
  isa       => CoercedInt,
  coerce    => 1,
  builder   => sub { shift->temp->max },
);

has temp_min_c => (
  lazy      => 1,
  is        => 'ro',
  isa       => CoercedInt,
  coerce    => 1,
  builder   => sub { f_to_c shift->temp_min_f },
);

has temp_max_c => (
  lazy      => 1,
  is        => 'ro',
  isa       => CoercedInt,
  coerce    => 1,
  builder   => sub { f_to_c shift->temp_max_f },
);


with 'Weather::OpenWeatherMap::Result::Forecast::Block';


1;

=pod

=head1 NAME

Weather::OpenWeatherMap::Result::Forecast::Day - Weather report for a single day

=head1 SYNOPSIS

  # Usually retrived via a Weather::OpenWeatherMap::Result::Forecast

=head1 DESCRIPTION

A L<Weather::OpenWeatherMap> weather forecast for a single day, provided by a
L<Weather::OpenWeatherMap::Result::Forecast> daily report.

This class consumes L<Weather::OpenWeatherMap::Result::Forecast::Block>; look
there for other applicable methods and attributes.

=head2 ATTRIBUTES

=head3 temp

An object containing the returned temperature data; this object provides
B<morn>, B<night>, B<eve>, B<min>, B<max>, B<day> accessors.

See L</temp_min_f>, L</temp_max_f>.

=head3 temp_min_f

The forecast low temperature, in degrees Fahrenheit.

=head3 temp_max_f

The forecast high temperature, in degrees Fahrenheit.

=head3 temp_min_c

The forecast low temperature, in degrees Celsius.

=head3 temp_max_c

The forecast high temperature, in degrees Celsius.

=head1 SEE ALSO

L<http://www.openweathermap.org/forecast16>

L<Weather::OpenWeatherMap::Result>

L<Weather::OpenWeatherMap::Result::Forecast>

L<Weather::OpenWeatherMap::Result::Forecast::Block>

L<Weather::OpenWeatherMap::Result::Forecast::Hour>

L<Weather::OpenWeatherMap::Result::Current>

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
