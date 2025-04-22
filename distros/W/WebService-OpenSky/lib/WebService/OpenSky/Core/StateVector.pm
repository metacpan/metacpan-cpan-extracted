package WebService::OpenSky::Core::StateVector;

# ABSTRACT: A class representing a state from the OpenSky Network API

use WebService::OpenSky::Moose;
our $VERSION = '0.5';

my @PARAMS = qw(
  icao24
  callsign
  origin_country
  time_position
  last_contact
  longitude
  latitude
  baro_altitude
  on_ground
  velocity
  true_track
  vertical_rate
  sensors
  geo_altitude
  squawk
  spi
  position_source
  category
);

param [@PARAMS];

around 'BUILDARGS' => sub ( $orig, $class, $state ) {
    my %value_for;
    @value_for{@PARAMS} = @$state;
    return $class->$orig(%value_for);
};

sub _get_params ($class) {@PARAMS}

method category_name() {
    my $category = $self->category // 0;
    $category = 0 if $category > 20;
    return '' unless $category;
    my @names = (
        'No information at all',
        'No ADS-B Emitter Category Information',
        'Light (< 15500 lbs)',
        'Small (15500 to 75000 lbs)',
        'Large (75000 to 300000 lbs)',
        'High Vortex Large (aircraft such as B-757)',
        'Heavy (> 300000 lbs)',
        'High Performance (> 5g acceleration and 400 kts)',
        'Rotorcraft',
        'Glider / sailplane',
        'Lighter-than-air',
        'Parachutist / Skydiver',
        'Ultralight / hang-glider / paraglider',
        'Reserved',
        'Unmanned Aerial Vehicle',
        'Space / Trans-atmospheric vehicle',
        'Surface Vehicle – Emergency Vehicle',
        'Surface Vehicle – Service Vehicle',
        'Point Obstacle (includes tethered balloons)',
        'Cluster Obstacle',
        'Line Obstacle',
    );
    return $names[$category];
}

method position_source_name() {
    my $source  = $self->position_source // return 'Uknown';
    my @sources = (
        'ADS-B',
        'ASTERIX',
        'MLAT',
        'FLARM',
    );
    return $sources[$source];
}

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OpenSky::Core::StateVector - A class representing a state from the OpenSky Network API

=head1 VERSION

version 0.5

=head1 SYNOPSIS

    use WebService::OpenSky;
    my $opensky = WebService::OpenSky->new;
    my $states  = $opensky->get_states;
    while ( my $vector = $states->next ) {
        say $vector->callsign;
        say $vector->latitude;
        say $vector->longitude;
    }

=head1 DESCRIPTION

This class is not to be instantiated directly. It is a read-only class representing an
L<OpenSky state vector|https://openskynetwork.github.io/opensky-api/index.html#state-vectors>.

All attributes are read-only.

=head2 C<icao24>

Unique ICAO 24-bit address of the transponder in hex string representation.

=head2 C<callsign>

Callsign of the vehicle (8 chars). Can be null if no callsign has been received.

=head2 C<origin_country>

Country name inferred from the ICAO 24-bit address.

=head2 C<time_position>

Unix timestamp (seconds) for the last position update. Can be null if no position report was received by OpenSky within the past 15s.

=head2 C<last_contact>

Unix timestamp (seconds) for the last update in general. This field is updated for any new, valid message received from the transponder.

=head2 C<longitude>

WGS-84 longitude in decimal degrees. Can be null.

=head2 C<latitude>

WGS-84 latitude in decimal degrees. Can be null.

=head2 C<baro_altitude>

Barometric altitude in meters. Can be null.

=head2 C<on_ground>

Boolean value which indicates if the position was retrieved from a surface position report.

=head2 C<velocity>

Velocity over ground in m/s. Can be null.

=head2 C<true_track>

True track in decimal degrees clockwise from north (north=0°). Can be null.

=head2 C<vertical_rate>

Vertical rate in m/s. A positive value indicates that the airplane is climbing, a negative value indicates that it descends. Can be null.

=head2 C<sensors>

IDs of the receivers which contributed to this state vector. Is null if no filtering for sensor was used in the request.

=head2 C<geo_altitude>

Geometric altitude in meters. Can be null.

=head2 C<squawk>

The transponder code aka Squawk. Can be null.

=head2 C<spi>

Whether flight status indicates special purpose indicator.

=head2 C<position_source_name>

Returns the name of the position source. Can be an empty string.

=head2 C<position_source>

Integer. Origin of this state’s position:

    0 = ADS-B
    1 = ASTERIX
    2 = MLAT
    3 = FLARM

=head2 C<category_name>

Returns the name of the aircraft category. Can be an empty string.

If C<< $opensky->get_states >> is called without C<extended> set to true, this
method will always return an empty string.

=head2 C<category>

Integer. Aircraft category. Can be null.

    0 = No information at all
    1 = No ADS-B Emitter Category Information
    2 = Light (< 15500 lbs)
    3 = Small (15500 to 75000 lbs)
    4 = Large (75000 to 300000 lbs)
    5 = High Vortex Large (aircraft such as B-757)
    6 = Heavy (> 300000 lbs)
    7 = High Performance (> 5g acceleration and 400 kts)
    8 = Rotorcraft
    9 = Glider / sailplane
    10 = Lighter-than-air
    11 = Parachutist / Skydiver
    12 = Ultralight / hang-glider / paraglider
    13 = Reserved
    14 = Unmanned Aerial Vehicle
    15 = Space / Trans-atmospheric vehicle
    16 = Surface Vehicle – Emergency Vehicle
    17 = Surface Vehicle – Service Vehicle
    18 = Point Obstacle (includes tethered balloons)
    19 = Cluster Obstacle
    20 = Line Obstacle

=head1 AUTHOR

Curtis "Ovid" Poe <curtis.poe@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Curtis "Ovid" Poe.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
