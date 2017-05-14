package WebService::BorisBikes;

use strict;
use warnings;

use LWP::Simple qw(get);
use XML::Simple qw(:strict);
use Perl6::Slurp;
use GIS::Distance::Lite;
use Geo::Postcode;
use Try::Tiny;
use Scalar::Util qw(looks_like_number);
use Carp qw(cluck confess);

use WebService::BorisBikes::Station;

=head1 NAME

WebService::BorisBikes - A very simple web service to wrap around the 
live Barclays cycle hire availibility data from the Transport for London website.

To use this module, please register and create an account at transport for london 
first.
http://www.tfl.gov.uk/businessandpartners/syndication/default.aspx

and always follow the usage guidelines ..
http://www.tfl.gov.uk/tfl/businessandpartners/syndication/assets/syndication-developer-guidelines.pdf

=head1 VERSION

version 0.14

=head1 SYNOPSIS

    use WebService::BorisBikes;

    my %params = ( 
        refresh_rate    => 120,    ## seconds
        debug_filename  => '/tmp/tflcycledata.xml',   
    );
    
    my $BB = WebService::BorisBikes->new( \%params );

=cut

our @station_fields = @WebService::BorisBikes::Station::station_fields;

my $TFL_LIVE_CYCLE_DATA_URL =
'http://www.tfl.gov.uk/tfl/syndication/feeds/cycle-hire/livecyclehireupdates.xml';

=head1 PUBLIC METHODS

=head2 new

Returns a WebService::BorisBikes object. Accepts a hashref with possible keys of 
refresh_rate & debug_filename.

The refresh rate specifies in seconds how often to update station information. 
Refresh is performed automatically if needed after calling one of 
the public methods.

The debug_filename specifies the absolute position of a local London Cycle 
Scheme XML feed and is used for testing and debugging.

=cut

sub new {
    my $class     = shift;
    my $rh_params = shift;

    my $self;
    foreach my $key ( keys %{$rh_params} ) {
        $self->{$key} = $rh_params->{$key};
    }

    if ( $self->{refresh_rate} < 60 && !$self->{debug_filename}) {
        die "Please specify a refresh time of 60 seconds or more.";
    }

    bless $self, $class;

    $self->_refresh_stations();

    return $self;
}

=head2 get_station_by_id 

Returns a WebService::BorisBikes::Station object of the given id 

    my $Station = $BB->get_station_by_id(533);

=cut

sub get_station_by_id {
    my $self = shift;
    my $id   = shift;

    # refresh stations if need be
    $self->_refresh_stations();

    return $self->{stations}->{$id};
}

=head2 get_all_stations 

Returns an hashref with keys being the station_id and values being a
WebService::BorisBikes::Station object.

    my $rh_stations = $BB->get_all_stations();

=cut

sub get_all_stations {
    my $self = shift;
    my $id   = shift;

    # refresh stations if need be
    $self->_refresh_stations();

    return $self->{stations};
}

=head2 get_meters_distance_between_two_stations

Returns the distance in meters between two station id's.

    my $meters = $BB->get_meters_distance_between_two_stations(566,547);
 
=cut

sub get_meters_distance_between_two_stations {
    my $self = shift;
    my ($id1, $id2) = @_;

    my $Station1 = $self->get_station_by_id($id1);
    my $Station2 = $self->get_station_by_id($id2);

    my $meters = $self->_get_meters_distance_between_two_coordinates(
       $Station1->get_lat(), 
       $Station1->get_long(), 
       $Station2->get_lat(), 
       $Station2->get_long(), 
    );

    # round off
    $meters = sprintf "%.0f", $meters;

    return $meters;
}

=head2 get_stations_nearby

Accepts a hashref, where the keys must contain 'distance' in meters 
and B<one> of the following ..

=over 4

=item 1

latlong => A comma delimited string of a valid latitude and longitude

    my $rhh_stations = $BB->get_stations_nearby( 
        { 'distance' => 200, latlong => '52.521,-0.102' }
    );

=item 2

postcode => A valid UK postcode (in greater London).

    my $rhh_stations = $BB->get_stations_nearby( 
        { 'distance' => 200, postcode => 'EC1M 5RF' }
    );

=back

If you do populate both latlong and postcode params, the latlong will be used,
and the postcode ignored.

Returns a hashref with the keys being station_ids and values being ...

    'distance' => in meters from the postcode/latlong argument 
    'obj' => the WebService::BorisBikes::Station object.  

For example:

   '246' => {
               'obj' => bless( {
                   'id'           => '246'
                   'nbEmptyDocks' => '39',
                    ...
               }, 'WebService::BorisBikes::Station' ),
               'distance' => '248.45237388466'

=cut

sub get_stations_nearby {
    my $self      = shift;
    my $rh_params = shift;

    # validate $distance
    if ( !looks_like_number($rh_params->{'distance'}) ) {
        cluck "distance parameter is not a number";
        return;
    }

    # get coordinates
    my ($lat,$long) = $self->_get_coordinates_from_place($rh_params); 

    # refresh stations if need be
    $self->_refresh_stations();

    return $self->_get_stations_near_lat_long($lat, 
                                              $long, 
                                              $rh_params->{'distance'}
    );
}

=head2 get_station_ids_nearby_order_by_distance_from

Accepts the same parameters as get_stations_nearby, but returns an arrayref
of station ids, ordered by distance from.


my $ra_stations = $BB->get_station_ids_nearby_order_by_distance_from ({
    postcode  => 'EC1M 5RF',    
});

=cut

sub get_station_ids_nearby_order_by_distance_from {
    my $self      = shift;
    my $rh_params = shift;

    # validate $distance
    if ( !looks_like_number($rh_params->{'distance'}) ) {
        cluck "distance parameter is not a number";
        return;
    }

    # get coordinates
    my ($lat,$long) = $self->_get_coordinates_from_place($rh_params); 

    # validate $lat & $long
    if ( !$self->_validate_lat_long($lat,$long) ) {
        cluck "not a valid latitude or longitude";
        return;
    } 

    # are coordinates even in greater london?
    if ( !$self->_coordinates_in_greater_london( $lat, $long ) ) {
        cluck "Coordinates don't appear to be in greater london";
        return;
    }

    # refresh stations if need be
    $self->_refresh_stations();

    # get station ids ordered by distance from
    my @station_ids =
        map   { $_->[0] } 
        sort  { $a->[1] <=> $b->[1] }
        grep  { $_->[1] <= $rh_params->{distance} } 
        map   { 
               [ 
                 $self->{stations}->{$_}->get_id(), 
                 $self->_get_meters_distance_between_station_and_coordinates(
                        $self->{stations}->{$_}, $lat, $long)
               ] 
             } keys %{$self->{stations}};

    return \@station_ids;
}

=head2 get_stations_by_name 

Search for station by their name attribute with case insensitive matching.
Returns a hashref, keys being station id and values being WebService::BorisBikes::Station
object.

    my $rh_stations = $BB->get_stations_by_name('holland park');

=cut

sub get_stations_by_name {
    my $self = shift;
    my $search = shift;

    # refresh stations if need be
    $self->_refresh_stations();

    my $rh_stations;
    foreach my $Station ( values %{$self->{stations}}) {
        if ( $Station->get_name =~ /$search/i ) {
            $rh_stations->{$Station->get_id()} = $Station;
        }
    }

    return $rh_stations;
}

=head1 PRIVATE METHODS 

=head2 _get_stations_near_lat_long

Accepts latitude, longitude and distance parameters finds the stations
within range.

=cut 

sub _get_stations_near_lat_long {
    my $self     = shift;
    my $lat      = shift;
    my $long     = shift;
    my $distance = shift;

    # validate $lat & $long
    if ( !$self->_validate_lat_long($lat,$long) ) {
        cluck "not a valid latitude or longitude";
        return;
    } 

    # are coordinates even in greater london?
    if ( !$self->_coordinates_in_greater_london( $lat, $long ) ) {
        cluck "Coordinates don't appear to be in greater london";
        return;
    }

    # find and return the stations within range
    my $rh_stations;
    foreach my $Station ( values %{$self->{stations}} ) {
        my $meters = $self->_get_meters_distance_between_station_and_coordinates(
                            $Station, $lat, $long);
        if ($meters <= $distance) {
            $rh_stations->{$Station->get_id()} = {
                'obj' => $Station,
                'distance' => $meters,
            } 
        }
    }

    return $rh_stations;
}

=head2 _refresh_stations

Populates $self->{stations} hashref. The key being the station_id,
and the value is a WebService::BorisBikes:Station object.

   $self->{stations}->{1} = WebService::BorisBikes::Station

=cut

sub _refresh_stations {
    my $self = shift;

    # do we need to refresh at all?
    return unless $self->_needs_refreshing();

    # yes, so clear current stations.
    delete $self->{stations};

    # get new data
    my $rhh_stations = $self->_get_station_data();

    # populate $self->{stations}
    foreach my $station_id ( keys %{$rhh_stations} ) {
        my $Station = WebService::BorisBikes::Station->new();
        foreach my $field (@station_fields) {
            my $setter = "set_$field";
            $Station->$setter( $rhh_stations->{$station_id}->{$field} );
        }
        $self->{stations}->{$station_id} = $Station;
    }

    # now set epoch since last refresh
    $self->{epoch_since_last_refresh} = time;

    warn "Refreshed station data!" if ($self->{debug_filename});

    return;
}

=head2 _needs_refreshing

Returns true if our station data has become stale. Returns false otherwise.

=cut

sub _needs_refreshing {
    my $self = shift;

    if ( !exists $self->{epoch_since_last_refresh} ) {
        return 1;
    }

    my $diff = time - $self->{epoch_since_last_refresh};

    if ( $diff >= $self->{refresh_rate} ) {
        return 1;
    }

    return;
}

=head2 _get_station_data 

If $self->{debug_filename} is not set, station data will be retrieved from the
tfl website using LWP::Simple.

Otherwise, station data will be slurped from a downloaded xml file in the  
absolute location of $self->{debug_filename}.

Returns an hashref of station data hashes, after setting 
$self->{epoch_since_last_refresh}.

=cut 

sub _get_station_data {
    my $self = shift;

    # get cycle data
    my $xmlfeed;
    if ( $self->{debug_filename} ) {
        if ( -e $self->{debug_filename} ) {
            $xmlfeed = slurp $self->{debug_filename};
        }
        else {
            confess "Failed to get station data, debug file: $self->{debug_filename} does not exist!";
            return;
        }
    }
    else {
        $xmlfeed = LWP::Simple::get($TFL_LIVE_CYCLE_DATA_URL);
    }

    # parse XML
    my $parsed = try {
        XMLin(
            $xmlfeed,
            ForceArray    => 0,
            KeyAttr       => {},
            SuppressEmpty => undef,
        );
    }
    catch {
        confess "Error in parsing tfl XML feed: $_";
    };

    # parse data
    my $rhh_stations;
    foreach my $station ( @{ $parsed->{station} } ) {
        $rhh_stations->{ $station->{id} }->{$_} = $station->{$_}
          foreach @station_fields;
    }

    return $rhh_stations;
}

=head2 _coordinates_in_greater_london

Return true if coordinate arguments are within a bounding box roughly the size 
of greater London.

=cut

sub _coordinates_in_greater_london {
    my $self = shift;
    my ( $lat, $long ) = @_;

    ## greater London bounding box roughly 45x45km
    my $greater_london_min_lat  = 51.161;
    my $greater_london_max_lat  = 51.667278;
    my $greater_london_min_long = -0.593938;
    my $greater_london_max_long = 0.448882;

    if (   $long >= $greater_london_min_long
        && $long <= $greater_london_max_long
        && $lat >= $greater_london_min_lat
        && $lat <= $greater_london_max_lat )
    {
        return 1;
    }

    return;
}

=head2 _get_meters_distance_between_station_and_coordinates

Returns the distance in meters between a WebService::BorisBikes::Station object
and WGS84 coordinates.

=cut

sub _get_meters_distance_between_station_and_coordinates {
    my $self = shift;
    my ( $Station, $lat, $long ) = @_;

    return $self->_get_meters_distance_between_two_coordinates(
        $Station->get_lat, $Station->get_long => $lat, $long
    );
}

=head2 _get_meters_distance_between_two_coordinates

Uses GIS::Distance::Lite to calculate the distance in meters between two
WGS84 coordinates, (Haversine formula).

=cut

sub _get_meters_distance_between_two_coordinates {
    my $self = shift;
    my ( $lat1, $long1, $lat2, $long2 ) = @_;

    return GIS::Distance::Lite::distance(
        $lat1, $long1 => $lat2, $long2
    );
}

=head2 _get_coordinates_from_place

Accepts the same hashref as WebService::BorisBikes::get_stations_nearby()
and returns a latitude and longitude.

=cut

sub _get_coordinates_from_place {
    my $self      = shift;
    my $rh_params = shift;

    my ($lat, $long);

    if ( $rh_params->{'latlong'} ) {
        ($lat, $long) = split ',', $rh_params->{'latlong'};
    } 
    elsif ( $rh_params->{'postcode'} ) {
        my $GeoPostCode = Geo::Postcode->new($rh_params->{'postcode'});
        if ( !$GeoPostCode->valid() ) {
            cluck "not a valid UK postcode";
            return;
        }
        $lat  = $GeoPostCode->lat;
        $long = $GeoPostCode->long;
    }

    return ($lat, $long);
}

=head2 _validate_lat_long

Returns true if parameters latitude is a float between -180 and 180
and longitude is a float between -90 and 90.

=cut

sub _validate_lat_long {
    my $self = shift;
    my ($lat, $long) = @_;
    return $self->_validate_lat($lat) && $self->_validate_long($long);
};



# latitude is a float between -180 and 180
sub _validate_lat {
    my $self = shift;
    my $val = shift;
    if ( defined($val) && $val =~ /^[\+\-]?\d+\.?\d*$/ ) { 
        return -180 <= $val && $val <= 180;
    }   
    else {
        return;
    }   
}

# longitude is a float between -90 and 90
sub _validate_long {
    my $self = shift;
    my $val = shift;
    if ( defined($val) && $val =~ /^[\+\-]?\d+\.?\d*$/ ) {
        return -90 <= $val && $val <= 90;
    }
    else {
        return;
    }
}

1;
