use strict;
use warnings;

use Test::More 0.88;

use WebService::MinFraud::Record::BillingAddress;

my $ba = WebService::MinFraud::Record::BillingAddress->new(
    is_in_ip_country        => 1,
    latitude                => 43.1,
    longitude               => 32.1,
    distance_to_ip_location => 100,
    is_postal_in_city       => 1
);

is( $ba->is_in_ip_country,        1,    'is_in_ip_country' );
is( $ba->is_postal_in_city,       1,    'is_postal_in_city' );
is( $ba->distance_to_ip_location, 100,  'distance_to_ip_location' );
is( $ba->longitude,               32.1, 'longitude' );
is( $ba->latitude,                43.1, 'latitude' );

done_testing;
