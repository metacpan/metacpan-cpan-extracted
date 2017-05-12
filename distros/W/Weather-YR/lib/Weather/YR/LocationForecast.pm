package Weather::YR::LocationForecast;
use Moose;
use namespace::autoclean;

extends 'Weather::YR::Base';

use DateTime;
use DateTime::Format::ISO8601;
use Mojo::URL;

use Weather::YR::LocationForecast::DataPoint;
use Weather::YR::LocationForecast::Day;

use Weather::YR::Model::Cloudiness;
use Weather::YR::Model::DewPointTemperature;
use Weather::YR::Model::Fog;
use Weather::YR::Model::Humidity;
use Weather::YR::Model::Precipitation::Symbol;
use Weather::YR::Model::Precipitation;
use Weather::YR::Model::Pressure;
use Weather::YR::Model::Probability::Temperature;
use Weather::YR::Model::Probability::Wind;
use Weather::YR::Model::Temperature;
use Weather::YR::Model::WindDirection;
use Weather::YR::Model::WindSpeed;

=head1 NAME

Weather::YR::LocationForecast - Object-oriented interface to Yr.no's "location
forecast" API.

=head1 DESCRIPTION

Don't use this class directly. Instead, access it from the L<Weather::YR> class.

=cut

has 'status_code' => ( isa => 'Num', is => 'rw', required => 0 );

has 'url'        => ( isa => 'Mojo::URL',                                          is => 'ro', lazy_build => 1 );
has 'schema_url' => ( isa => 'Mojo::URL',                                          is => 'ro', lazy_build => 1 );
has 'datapoints' => ( isa => 'ArrayRef[Weather::YR::LocationForecast::DataPoint]', is => 'ro', lazy_build => 1 );
has 'days'       => ( isa => 'ArrayRef[Weather::YR::LocationForecast::Day]',       is => 'ro', lazy_build => 1 );

has 'now'        => ( isa => 'Weather::YR::LocationForecast::Day',                 is => 'ro', lazy_build => 1 );
has 'today'      => ( isa => 'Weather::YR::LocationForecast::Day',                 is => 'ro', lazy_build => 1 );
has 'tomorrow'   => ( isa => 'Weather::YR::LocationForecast::Day',                 is => 'ro', lazy_build => 1 );

=head1 METHODS

=head2 url

Returns the URL to YR.no's location forecast service. This is handy if you
want to retrieve the XML from YR.no yourself;

    my $yr = Weather::YR->new(
        lat => 63.590833,
        lon => 10.741389,
    );

    my $url = $yr->location_forecast->url;

    my $xml = My FancyHttpClient->new->get( $url );

    my $yr = Weather::YR->new(
        xml => $xml,
        tz  => DateTime::TimeZone->new( name => 'Europe/Oslo' ),
    );

    my $forecast = $yr->location_forecast;

=cut

sub _build_url {
    my $self = shift;

    my $url = $self->service_url;
    $url->path ( '/weatherapi/locationforecast/1.9/' );
    $url->query( lat => $self->lat, lon => $self->lon, msl => $self->msl );

    return $url;
    # return 'http://api.yr.no/weatherapi/locationforecast/1.9/?lat=' . $self->lat . ';lon=' . $self->lon . ';msl=' . $self->msl;
}

=head2 schema_url

Returns the URL to YR.no' location forecast service XML schema. This is used
internally for validating the XML output from YR.no itself.

=cut

sub _build_schema_url {
    my $self = shift;

    my $url = $self->service_url;
    $url->path( '/weatherapi/locationforecast/1.9/schema' );

    return $url;
}

=head2 datapoints

Returns an array reference of L<Weather::YR::LocationForecast::DataPoint> instances.

=cut

sub _build_datapoints {
    my $self = shift;

    my @datapoints = ();

    if ( my $xml_ref = $self->xml_ref ) {
        # use Data::Dumper;
        # print STDOUT Dumper( $xml_ref );
        # die;
        # my $times     = $xml_ref->{weatherdata}->{product}->{time} || [];
        my $times     = $xml_ref->{product}->{time} || [];
        my $datapoint = undef;

        foreach my $t ( @{$times} ) {
            my $from = $self->date_to_datetime( $t->{from} );
            my $to   = $self->date_to_datetime( $t->{to  } );

            if ( $t->{location}->{temperature} ) {
                my $loc = $t->{location};

                if ( defined $datapoint ) {
                    push( @datapoints, $datapoint );
                    $datapoint = undef;
                }

                $datapoint = Weather::YR::LocationForecast::DataPoint->new(
                    from => $from,
                    to   => $to,
                    lang => $self->lang,
                    type => $t->{datatype},

                    temperature => Weather::YR::Model::Temperature->new(
                        from    => $from,
                        to      => $to,
                        lang    => $self->lang,
                        celsius => $loc->{temperature}->{value},
                    ),

                    wind_direction => Weather::YR::Model::WindDirection->new(
                        from    => $from,
                        to      => $to,
                        lang    => $self->lang,
                        degrees => $loc->{windDirection}->{deg},
                        name    => $loc->{windDirection}->{name},
                    ),

                    wind_speed => Weather::YR::Model::WindSpeed->new(
                        from     => $from,
                        to       => $to,
                        lang     => $self->lang,
                        mps      => $loc->{windSpeed}->{mps},
                        beaufort => $loc->{windSpeed}->{beaufort},
                        name     => $loc->{windSpeed}->{name},
                    ),

                    humidity => Weather::YR::Model::Humidity->new(
                        from    => $from,
                        to      => $to,
                        lang    => $self->lang,
                        percent => $loc->{humidity}->{value},
                    ),

                    pressure => Weather::YR::Model::Pressure->new(
                        from => $from,
                        to   => $to,
                        lang => $self->lang,
                        hPa  => $loc->{pressure}->{value},
                    ),

                    cloudiness => Weather::YR::Model::Cloudiness->new(
                        from    => $from,
                        to      => $to,
                        lang    => $self->lang,
                        percent => $loc->{cloudiness}->{percent},
                    ),

                    fog => Weather::YR::Model::Fog->new(
                        from    => $from,
                        to      => $to,
                        lang    => $self->lang,
                        percent => $loc->{fog}->{percent},
                    ),

                    dew_point_temperature => Weather::YR::Model::DewPointTemperature->new(
                        from    => $from,
                        to      => $to,
                        lang    => $self->lang,
                        celsius => $loc->{dewpointTemperature}->{value},
                    ),

                    temperature_probability => Weather::YR::Model::Probability::Temperature->new(
                        from => $from,
                        to   => $to,
                        lang => $self->lang,
                        value => $loc->{temperatureProbability}->{value},
                    ),

                    wind_probability => Weather::YR::Model::Probability::Wind->new(
                        from => $from,
                        to   => $to,
                        lang => $self->lang,
                        value => $loc->{windProbability}->{value},
                    ),
                );
            }
            elsif ( my $p = $t->{location}->{precipitation} ) {
                my $precipitation = Weather::YR::Model::Precipitation->new(
                    from   => $from,
                    to     => $to,
                    lang   => $self->lang,
                    value  => $p->{value},
                    min    => $p->{minvalue},
                    max    => $p->{maxvalue},
                    symbol => Weather::YR::Model::Precipitation::Symbol->new(
                        from   => $from,
                        to     => $to,
                        lang   => $self->lang,
                        id     => $t->{location}->{symbol}->{id},
                        number => $t->{location}->{symbol}->{number},
                    ),
                );

                $datapoint->add_precipitation( $precipitation );
            }
        }
    }
    else {
        warn "No XML to generate forecast from!";
    }

    return \@datapoints;
}

=head2 days

Returns an array reference of L<Weather::YR::LocationForecast::Day> instances.

=cut

sub _build_days {
    my $self = shift;

    my %day_datapoints = ();

    foreach my $datapoint ( @{$self->datapoints} ) {
        push( @{$day_datapoints{$datapoint->{from}->ymd}}, $datapoint );
    }

    my @days = ();

    foreach my $date ( sort keys %day_datapoints ) {
        my $day = Weather::YR::LocationForecast::Day->new(
            date       => DateTime::Format::ISO8601->parse_datetime( $date ),
            datapoints => $day_datapoints{ $date },
        );

        push( @days, $day );
    }

    return \@days;
}

=head2 now

Returns a L<Weather::YR::LocationForecast::Day> instance, representing the
closest forecast in time.

=cut

sub _build_now {
    my $self = shift;

    my $now        = DateTime->now( time_zone => 'UTC' );
    my $closest_dp = undef;

    foreach my $dp ( @{$self->today->datapoints} ) {
        unless ( defined $closest_dp ) {
            $closest_dp = $dp;
            next;
        }

        my $diff_from_now = abs( $dp->from->epoch - $now->epoch );

        if ( $diff_from_now < ( abs($closest_dp->from->epoch - $now->epoch) ) ) {
            $closest_dp = $dp;
        }
    }

    return Weather::YR::LocationForecast::Day->new(
        date       => $closest_dp->from,
        datapoints => [ $closest_dp ],
    );
}

=head2 today

Returns a L<Weather::YR::LocationForecast::Day> instance, representing today's
weather.

=cut

sub _build_today {
    my $self = shift;

    return $self->days->[0];
}

=head2 tomorrow

Returns a L<Weather::YR::LocationForecast::Day> instance, representing
tomorrow's weather.

=cut

sub _build_tomorrow {
    my $self = shift;

    return $self->days->[1];
}

__PACKAGE__->meta->make_immutable;

1;
