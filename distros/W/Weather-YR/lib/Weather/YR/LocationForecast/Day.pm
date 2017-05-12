package Weather::YR::LocationForecast::Day;
use Moose;
use namespace::autoclean;

extends 'Weather::YR::Day';

=head1 NAME

Weather::YR::LocationForecast::Day - Class that holds weather data for one day.

=head1 DESCRIPTION

Don't use this class directly. Instead, access it via L<Weather::YR> and
L<Weather::YR::LocationForecast>.

=cut

# Temperature
has 'temperatures'    => ( isa => 'ArrayRef[Weather::YR::Model::Temperature]', is => 'ro', lazy_build => 1 );
has 'temperature'     => ( isa => 'Weather::YR::Model::Temperature',           is => 'ro', lazy_build => 1 );

# Precipitation
has 'precipitations' => ( isa => 'ArrayRef[Weather::YR::Model::Precipitation]', is => 'ro', lazy_build => 1 );
has 'precipitation'  => ( isa => 'Weather::YR::Model::Precipitation',           is => 'ro', lazy_build => 1 );

# Wind direction
has 'wind_directions' => ( isa => 'ArrayRef[Weather::YR::Model::WindDirection]', is => 'ro', lazy_build => 1 );
has 'wind_direction'  => ( isa => 'Weather::YR::Model::WindDirection',           is => 'ro', lazy_build => 1 );

# Wind speed
has 'wind_speeds'    => ( isa => 'ArrayRef[Weather::YR::Model::WindSpeed]', is => 'ro', lazy_build => 1 );
has 'wind_speed'     => ( isa => 'Weather::YR::Model::WindSpeed',           is => 'ro', lazy_build => 1 );

# Humidity
has 'humidities'   => ( isa => 'ArrayRef[Weather::YR::Model::Humidity]', is => 'ro', lazy_build => 1 );
has 'humidity'     => ( isa => 'Weather::YR::Model::Humidity',           is => 'ro', lazy_build => 1 );

# Pressure
has 'pressures'    => ( isa => 'ArrayRef[Weather::YR::Model::Pressure]', is => 'ro', lazy_build => 1 );
has 'pressure'     => ( isa => 'Weather::YR::Model::Pressure',           is => 'ro', lazy_build => 1 );

# Cloudiness
has 'cloudinesses'   => ( isa => 'ArrayRef[Weather::YR::Model::Cloudiness]', is => 'ro', lazy_build => 1 );
has 'cloudiness'     => ( isa => 'Weather::YR::Model::Cloudiness',           is => 'ro', lazy_build => 1 );

# Fog
has 'fogs'    => ( isa => 'ArrayRef[Weather::YR::Model::Fog]', is => 'ro', lazy_build => 1 );
has 'fog'     => ( isa => 'Weather::YR::Model::Fog',           is => 'ro', lazy_build => 1 );

# Dew point temperature
has 'dew_point_temperatures'    => ( isa => 'ArrayRef[Weather::YR::Model::DewPointTemperature]', is => 'ro', lazy_build => 1 );
has 'dew_point_temperature'     => ( isa => 'Weather::YR::Model::DewPointTemperature',           is => 'ro', lazy_build => 1 );

=head1 METHODS

This class inherits all the methods from L<Weather::YR::Day> and provides the
following new methods:

=cut

sub _ok_hour {
    my $self = shift;
    my $hour = shift;

    if ( defined $hour && ($hour >= 12 && $hour <= 15) ) {
        return 1;
    }
    else {
        return 0;
    }
}

=head2 temperatures

Returns an array reference of all the L<Weather::YR::Model::Temperature>
data points for this day.

=cut

sub _build_temperatures {
    my $self = shift;

    return [ map { $_->temperature } @{$self->datapoints} ];
}

=head2 temperature

Returns the "most logical" L<Weather::YR::Model::Temperature> data point for
this day.

This works so that if you are working with "now", it will pick the data point
closest to the current time. If you are working with any other days, including
"today", it will return the data noon point, or the closest one after noon if
there isn't one for noon.

=cut

sub _build_temperature {
    my $self = shift;

    foreach ( @{$self->temperatures} ) {
        if ( $self->_ok_hour($_->from->hour) ) {
            return $_;
        }
    }

    return $self->temperatures->[0];
}

=head2 precipitations

Returns an array reference of all the L<Weather::YR::Model::Precipitation>
data points for this day.

=cut

sub _build_precipitations {
    my $self = shift;

    my @precips = ();

    foreach ( @{$self->datapoints} ) {
        foreach ( @{$_->precipitations} ) {
            if ( $_->from->ymd eq $self->date->ymd ) {
                push( @precips, $_ );
            }
        }
    }

    return \@precips;
}

=head2 precipitation

Returns "the most logical" L<Weather::YR::Model::Precipitation> data point
for this day.

This works so that if you are working with "now", it will pick the data point
closest to the current time. If you are working with any other days, including
"today", it will return the data noon point, or the closest one after noon if
there isn't one for noon.

=cut

sub _build_precipitation {
    my $self = shift;

    foreach ( @{$self->precipitations} ) {
        if ( $self->_ok_hour($_->from->hour) ) {
            return $_;
        }
    }

    return $self->precipitations->[0];
}

=head2 wind_directions

Returns an array reference of L<Weather::YR::Model::WindDirection> data points
for this day.

=cut

sub _build_wind_directions {
    my $self = shift;

    return [ map { $_->wind_direction } @{$self->datapoints} ];
}

=head2 wind_direction

Returns "the most logical" L<Weather::YR::Model::WindDirection> data point
for this day.

This works so that if you are working with "now", it will pick the data point
closest to the current time. If you are working with any other days, including
"today", it will return the data noon point, or the closest one after noon if
there isn't one for noon.

=cut

sub _build_wind_direction {
    my $self = shift;

    foreach ( @{$self->wind_directions} ) {
        if ( $self->_ok_hour($_->from->hour) ) {
            return $_;
        }
    }

    return $self->wind_directions->[0];
}

=head2 wind_speeds

Returns an array reference of L<Weather::YR::Model::WindSpeed> data points
for this day.

=cut

sub _build_wind_speeds {
    my $self = shift;

    return [ map { $_->wind_speed } @{$self->datapoints} ];
}

=head2 wind_speed

Returns "the most logical" L<Weather::YR::Model::WindSpeed> data point
for this day.

This works so that if you are working with "now", it will pick the data point
closest to the current time. If you are working with any other days, including
"today", it will return the data noon point, or the closest one after noon if
there isn't one for noon.

=cut

sub _build_wind_speed {
    my $self = shift;

    foreach ( @{$self->wind_speeds} ) {
        if ( $self->_ok_hour($_->from->hour) ) {
            return $_;
        }
    }

    return $self->wind_speed->[0];
}

=head2 humidities

Returns an array reference of L<Weather::YR::Model::WindSpeed> data points
for this day.

=cut

sub _build_humidities {
    my $self = shift;

    return [ map { $_->humidity } @{$self->datapoints} ];
}

=head2 humidity

Returns "the most logical" L<Weather::YR::Model::Humidity> data point
for this day.

This works so that if you are working with "now", it will pick the data point
closest to the current time. If you are working with any other days, including
"today", it will return the data noon point, or the closest one after noon if
there isn't one for noon.

=cut

sub _build_humidity {
    my $self = shift;

    foreach ( @{$self->humidities} ) {
        if ( $self->_ok_hour($_->from->hour) ) {
            return $_;
        }
    }

    return $self->humidities->[0];
}

=head2 pressures

Returns an array reference of L<Weather::YR::Model::Pressure> data points
for this day.

=cut

sub _build_pressures {
    my $self = shift;

    return [ map { $_->pressure } @{$self->datapoints} ];
}

=head2 pressure

Returns "the most logical" L<Weather::YR::Model::Humidity> data point
for this day.

This works so that if you are working with "now", it will pick the data point
closest to the current time. If you are working with any other days, including
"today", it will return the data noon point, or the closest one after noon if
there isn't one for noon.

=cut

sub _build_pressure {
    my $self = shift;

    foreach ( @{$self->pressures} ) {
        if ( $self->_ok_hour($_->from->hour) ) {
            return $_;
        }
    }

    return $self->pressures->[0];
}

=head2 cloudinesses

Returns an array reference of L<Weather::YR::Model::Cloudiness> data points
for this day.

=cut

sub _build_cloudinesses {
    my $self = shift;

    return [ map { $_->cloudiness } @{$self->datapoints} ];
}

=head2 cloudiness

Returns "the most logical" L<Weather::YR::Model::Cloudiness> data point
for this day.

This works so that if you are working with "now", it will pick the data point
closest to the current time. If you are working with any other days, including
"today", it will return the data noon point, or the closest one after noon if
there isn't one for noon.

=cut

sub _build_cloudiness {
    my $self = shift;

    foreach ( @{$self->cloudinesses} ) {
        if ( $self->_ok_hour($_->from->hour) ) {
            return $_;
        }
    }

    return $self->cloudinesses->[0];
}

=head2 fogs

Returns an array reference of L<Weather::YR::Model::Fog> data points
for this day.

=cut

sub _build_fogs {
    my $self = shift;

    return [ map { $_->fog } @{$self->datapoints} ];
}

=head2 fog

Returns "the most logical" L<Weather::YR::Model::Fog> data point
for this day.

This works so that if you are working with "now", it will pick the data point
closest to the current time. If you are working with any other days, including
"today", it will return the data noon point, or the closest one after noon if
there isn't one for noon.

=cut

sub _build_fog {
    my $self = shift;

    foreach ( @{$self->fogs} ) {
        if ( $self->_ok_hour($_->from->hour) ) {
            return $_;
        }
    }

    return $self->fogs->[0];
}

=head2 dew_point_temperatures

Returns an array reference of L<Weather::YR::Model::DewPointTemperature> data points
for this day.

=cut

sub _build_dew_point_temperatures {
    my $self = shift;

    return [ map { $_->dew_point_temperature } @{$self->datapoints} ];
}

=head2 dew_point_temperature

Returns "the most logical" L<Weather::YR::Model::DewPointTemperature> data point
for this day.

This works so that if you are working with "now", it will pick the data point
closest to the current time. If you are working with any other days, including
"today", it will return the data noon point, or the closest one after noon if
there isn't one for noon.

=cut

sub _build_dew_point_temperature {
    my $self = shift;

    foreach ( @{$self->dew_point_temperatures} ) {
        if ( $self->_ok_hour($_->from->hour) ) {
            return $_;
        }
    }

    return $self->dew_point_temperatures->[0];
}

#
# The End
#
__PACKAGE__->meta->make_immutable;

1;
