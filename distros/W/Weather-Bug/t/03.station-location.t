use Test::More tests => 1 + 25;

use warnings;
use strict;

use Weather::Bug;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::Weather::Bug;
use Test::Group;

my %cities = map { $_ => 1 } qw/Houston Bellaire/;
my %zipcodes = map { $_ => 1 }
      qw/77007 77008 77024 77025 77030 77035
         77036 77045 77047 77055 77056 77072
         77077 77081 77083 77401 77033 77019
         77204/;

my $wxbug = Test::Weather::Bug->new( -key => 'FAKELICENSEKEY' );

my @stations = $wxbug->list_stations( 77096 );

is( scalar( @stations ), 25, 'Right number of stations returned' );

my $index = 0;
foreach my $s (@stations)
{
    my $loc = $s->location();
    location_ok( $loc, "Station $index: location" );
    ++$index;
}

# -------
# Utility functions to simplify the testing.
sub location_ok
{
    my $l = shift;
    my $name = shift || 'location_ok';

    test $name => sub {
        isa_ok( $l, 'Weather::Bug::Location' );
        ok( exists $cities{$l->city()}, "'@{[$l->city()]}, ' not in city list" );
        ok( exists $zipcodes{$l->zipcode()}, "@{[$l->zipcode()]}, ' not in zipcode list" );
        is( $l->state(), 'TX', 'Wrong state' );

        ok( $l->has_latitude(), 'Has latitude' );
        ok( (29.60 <= $l->latitude() and $l->latitude() <= 29.8), "Invalid latitude @{[$l->latitude()]}" );
        ok( $l->has_longitude(), 'Has longitude' );
        ok( (-95.62 <= $l->longitude() and $l->longitude() <= -95.33), "Invalid longitude @{[$l->longitude()]}" );
        ok( $l->has_distance(), 'Has distance' );
        ok( (1 <= $l->distance() and $l->distance() <= 9.2), "Invalid distance @{[$l->distance()]}" );
        ok( !$l->has_zone(), 'Should have no zone' );
    };
}

