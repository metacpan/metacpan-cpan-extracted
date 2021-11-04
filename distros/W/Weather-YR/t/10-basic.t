#!/usr/bin/env perl
#
use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::More;

plan tests => 4;

use Weather::YR;

my $yr = Weather::YR->new(
    lat => 63.590833,
    lon => 10.741389,
);

# Make sure that 'lat' and 'lon' is restricted to four decimals, ref.
# https://api.met.no/doc/TermsOfService#traffic
is( $yr->lat, 63.5908 );
is( $yr->lon, 10.7414 );

$yr->lat( 63.590833 );

is( $yr->lat, 63.5908 );

# Make sure that the API URLs are correct.
is( $yr->location_forecast->url, $yr->service_url->to_string . '/weatherapi/locationforecast/2.0/classic?lat=63.5908&lon=10.7414&altitude=0', 'URL for location forecast is OK.' );

# The End
done_testing;
