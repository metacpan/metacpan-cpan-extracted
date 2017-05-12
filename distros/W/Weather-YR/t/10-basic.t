#!/usr/bin/env perl
#
use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::More;

plan tests => 1;

use Weather::YR;

my $yr = Weather::YR->new(
    lat => 63.590833,
    lon => 10.741389,
);

# Make sure that the API URLs are correct.
is( $yr->location_forecast->url, $yr->service_url->to_string . '/weatherapi/locationforecast/1.9/?lat=63.590833&lon=10.741389&msl=0', 'URL for location forecast is OK.' );

# The End
done_testing;
