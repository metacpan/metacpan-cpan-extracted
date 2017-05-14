# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WebService-BorisBikes.t'

#########################

use strict;
use warnings;

use Test::More;
use Test::Warn;
use_ok('Class::Accessor');
use_ok('WebService::BorisBikes');
use_ok('WebService::BorisBikes::Station');

##########################################################################
## create WebService::BorisBikes object
##

my %params = (
    'refresh_rate'   => 2,
    'debug_filename' => 't/livecyclehireupdates.xml',
);

my $BB = WebService::BorisBikes->new( \%params );
isa_ok( $BB, 'WebService::BorisBikes',
    'instantiated WebService::BorisBikes object' );

# test the refresh works
sleep 2;
warning_is { $BB->get_station_by_id(547); } "Refreshed station data!",
  "Got correct refresh warning";

##########################################################################
## test public methods and variables
##

# station_fields
my @expected =
  qw/id name terminalName lat long installed locked installDate temporary nbBikes nbEmptyDocks nbDocks/;
is_deeply( \@WebService::BorisBikes::Station::station_fields,
    \@expected, 'station fields are correct' );

# get_all_station()
my $rh_all_stations = $BB->get_all_stations();
is( scalar keys %{$rh_all_stations}, 553, "Got 553 stations" );

# get_station_by_id()
my $Station = $BB->get_station_by_id(547);
isa_ok( $Station, 'WebService::BorisBikes::Station' );

my %expected = (
    'terminalName' => '200127',
    'nbEmptyDocks' => '12',
    'locked'       => 'false',
    'lat'          => '51.5094740',
    'installed'    => 'true',
    'name'         => 'East India DLR, Blackwall',
    'installDate'  => undef,
    'temporary'    => 'false',
    'nbDocks'      => '51',
    'long'         => '-0.002275',
    'nbBikes'      => '35',
    'id'           => '547'
);

foreach my $key (@WebService::BorisBikes::Station::station_fields) {
    my $attr = "get_$key";
    is( $Station->$attr(), $expected{$key}, "$key value is correct" );
}

# get_meters_distance_between_two_stations()
my $Station2 = $BB->get_station_by_id(591);
my $meters = $BB->get_meters_distance_between_two_stations( 547, 591 );
is( $meters, 15367, "Distance between two stations is correct" );

# get_stations_nearby() postcode
my $rh_stations =
  $BB->get_stations_nearby( { 'distance' => 330, 'postcode' => 'EC1M5RF' } );
is( scalar keys %{$rh_stations}, 4, 'got 2 stations nearby postcode' );
my @ids =
  sort { $a <=> $b }
  map  { $rh_stations->{$_}->{obj}->get_id() } keys %{$rh_stations};
my @expected_ids = qw/95 135 203 246/;
is_deeply( \@ids, \@expected_ids,
    'got correct station ids nearby by postcode' );

# get_stations_nearby() latlong
$rh_stations = $BB->get_stations_nearby(
    { 'distance' => 330, 'latlong' => '51.521,-0.102' } );
is( scalar keys %{$rh_stations}, 4, 'got 2 stations nearby latlong' );
@ids =
  sort { $a <=> $b }
  map  { $rh_stations->{$_}->{obj}->get_id() } keys %{$rh_stations};
@expected_ids = qw/95 135 203 246/;
is_deeply( \@ids, \@expected_ids, 'got correct station ids nearby by latlong' );

# get_stations_by_name
$rh_stations = $BB->get_stations_by_name('holland park');
@ids = sort map { $rh_stations->{$_}->get_id() } keys %{$rh_stations};
##@expected_ids = qw/559 515/;
@expected_ids = qw/515 559/;
is_deeply( \@ids, \@expected_ids, 'got correct station ids by name' );

# get_station_ids_nearby_order_by_distance_from()
my $ra_station_ids = $BB->get_station_ids_nearby_order_by_distance_from(
    {
        'distance' => 330,
        'postcode' => 'EC1M 5RF'
    }
);
@expected_ids = qw/246 135 203 95/;
is_deeply( $ra_station_ids, \@expected_ids,
    'got correct station ids nearby ordered by distance' );

done_testing();
