use strict;
use warnings;

use Test::More 0.88;

use WebService::MinFraud::Record::ShippingAddress;

my $ba = WebService::MinFraud::Record::ShippingAddress->new(
    is_in_ip_country            => 1,
    latitude                    => 43.1,
    longitude                   => 32.1,
    distance_to_ip_location     => 100,
    is_postal_in_city           => 1,
    is_high_risk                => 1,
    distance_to_billing_address => 200,
);

is( $ba->is_in_ip_country,            1,    'is_in_ip_country' );
is( $ba->is_postal_in_city,           1,    'is_postal_in_city' );
is( $ba->distance_to_ip_location,     100,  'distance_to_ip_location' );
is( $ba->longitude,                   32.1, 'longitude' );
is( $ba->latitude,                    43.1, 'latitude' );
is( $ba->is_high_risk,                1,    'is_high_risk' );
is( $ba->distance_to_billing_address, 200,  'distance_to_billing_address' );

done_testing;
