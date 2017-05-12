package Weather::YR::LocationForecast::DataPoint;
use Moose;
use namespace::autoclean;

extends 'Weather::YR::DataPoint';

=head1 NAME

Weather::YR::LocationForecast::DataPoint - Class that represents a location
forecast's data point.

=head1 DESCRIPTION

Don't use this class directly; it's used as a "background helper class" for
L<Weather::YR::LocationForecast>.

=head1 METHODS

This class inherits all the methods from L<Weather::YR::DataPoint> and provides
the following new methods:

=head2 temperature

Returns this data point's L<Weather::YR::Model::Temperature> object.

=cut

has 'temperature' => (
    isa      => 'Weather::YR::Model::Temperature',
    is       => 'ro',
    required => 1,
);

=head2 wind_direction

Returns this data point's L<Weather::YR::Model::WindDirection> object.

=cut

has 'wind_direction' => (
    isa      => 'Weather::YR::Model::WindDirection',
    is       => 'ro',
    required => 1,
);

=head2 wind_speed

Returns this data point's L<Weather::YR::Model::::WindSpeed> object.

=cut

has 'wind_speed' => (
    isa      => 'Weather::YR::Model::WindSpeed',
    is       => 'ro',
    required => 1,
);

=head2 humidity

Returns this data point's L<Weather::YR::Model::Humidity> object.

=cut

has 'humidity' => (
    isa      => 'Weather::YR::Model::Humidity',
    is       => 'ro',
    required => 1,
);

=head2 pressure

Returns this data point's L<Weather::YR::Model::Pressure> object.

=cut

has 'pressure' => (
    isa      => 'Weather::YR::Model::Pressure',
    is       => 'ro',
    required => 1,
);

=head2 cloudiness

Returns this data point's L<Weather::YR::Model::Cloudiness> object.

=cut

has 'cloudiness' => (
    isa      => 'Weather::YR::Model::Cloudiness',
    is       => 'ro',
    required => 1,
);

=head2 fog

Returns this data point's L<Weather::YR::Model::Fog> object.

=cut

has 'fog' => (
    isa      => 'Weather::YR::Model::Fog',
    is       => 'ro',
    required => 1,
);

=head2 dew_point_temperature

Returns this data point's L<Weather::YR::Model::DewPointTemperature> object.

=cut

has 'dew_point_temperature' => (
    isa      => 'Weather::YR::Model::DewPointTemperature',
    is       => 'ro',
    required => 1,
);

=head2 temperature_probability

Returns this data point's L<Weather::YR::Model::Probability::Temperature> object.

=cut

has 'temperature_probability' => (
    isa      => 'Weather::YR::Model::Probability::Temperature',
    is       => 'ro',
    required => 1,
);

=head2 wind_probability

Returns this data points L<Weather::YR::Model::Probability::Wind> object.

=cut

has 'wind_probability' => (
    isa      => 'Weather::YR::Model::Probability::Wind',
    is       => 'ro',
    required => 1,
);

=head2 precipitations

Returns an array reference of L<Weather::YR::Model::Precipitation> objects for
this data point.

=cut

has 'precipitations' => (
    isa      => 'ArrayRef[Weather::YR::Model::Precipitation]',
    is       => 'rw',
    required => 0,
    default  => sub { [] },
);

sub add_precipitation {
    my $self = shift;
    my $p    = shift;

    push( @{$self->precipitations}, $p );
}

#
# The End
#
__PACKAGE__->meta->make_immutable;

1;
