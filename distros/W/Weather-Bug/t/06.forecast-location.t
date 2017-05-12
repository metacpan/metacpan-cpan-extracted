use Test::More tests => 9;

use warnings;
use strict;

use Weather::Bug;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::Weather::Bug;

my $wxbug = Test::Weather::Bug->new( -key => 'FAKELICENSEKEY' );

my $forecast = $wxbug->get_forecast( 77096 );
my $loc = $forecast->location();

isa_ok( $loc, 'Weather::Bug::Location' );
is( $loc->city(), 'Houston', 'City is correct' );
is( $loc->state(), 'TX', 'State is correct' );
is( $loc->zipcode(), 77096, 'Zipcode is correct' );
ok( !$loc->has_latitude(), 'Has no latitude' );
ok( !$loc->has_longitude(), 'Has no longitude' );
ok( !$loc->has_distance(), 'Has no distance' );
ok( $loc->has_zone(), 'Should have a zone' );
is( $loc->zone(), 'TX213', 'Zone is correct' );

