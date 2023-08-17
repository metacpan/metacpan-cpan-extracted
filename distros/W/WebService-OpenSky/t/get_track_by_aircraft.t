#!/usr/bin/env perl

use lib 'lib', 't/lib';
use Test::Most;
use WebService::OpenSky::Test qw( set_response );

my $opensky = WebService::OpenSky->new( testing => 1 );

my $now          = time;
my $one_hour_ago = $now - 3600;

my $icao24 = 'c8229e';

subtest 'Flight data is available' => sub {
    set_response( aircraft_track() );
    my $response = $opensky->get_track_by_aircraft( $icao24, $one_hour_ago );
    ok !$response->_inflated, 'We should not have inflated the response yet';
    my $flighttrack_raw = $response->raw_response;
    ok !$response->_inflated, 'We should not have inflated the response yet';

    is ref($flighttrack_raw), 'HASH', 'We should be able to fetch the raw response';
    my $path = $flighttrack_raw->{path};
    is scalar @$path, 20, 'We should have three vectors';

    my $waypoint = $response->iterator;
    ok $response->_inflated,                                   'The response should be inflated now';
    ok $waypoint->isa('WebService::OpenSky::Utils::Iterator'), 'We should have an iterator';
    is $response->count, 20, 'We should have three waypoint';

    my @params    = $waypoint->first->_get_params;
    my $waypoints = $response->raw_response->{path};
    while ( my $waypoint = $response->next ) {
        my $raw_waypoint = shift @$waypoints;
        foreach my $param (@params) {
            my $value = shift @$raw_waypoint;
            no warnings 'uninitialized';
            is $waypoint->$param, $value, "The $param should be the same: '$value'";
        }
    }
};

subtest 'No waypoints available' => sub {
    my $not_found = <<'END';
HTTP/1.1 404 Not Found
Content-Length: 0
Date: Sun, 28 May 2023 08:02:21 GMT
END
    set_response($not_found);
    my $states = $opensky->get_track_by_aircraft( 'c8229e', $one_hour_ago );
    ok !$states->count, 'We should have no flight track data if we have a 404';
};

done_testing;

sub aircraft_track {
    return <<'END';
HTTP/1.1 200 OK
Cache-Control: no-cache, no-store, max-age=0, must-revalidate
Connection: keep-alive
Content-Length: 2732
Content-Type: application/json;charset=UTF-8
Date: Mon, 05 Jun 2023 06:35:37 GMT
Expires: 0
Pragma: no-cache
Server: nginx/1.17.6
Set-Cookie: XSRF-TOKEN=2af61d6e-ca5d-43a6-ad6f-a83b9c4e3e9c; Path=/
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block

{
    "icao24":    "c8229e",
    "callsign":  "SDA792  ",
    "startTime": 1.685941193E9,
    "endTime":   1.685945747E9,
    "path":      [
        [1685941193, -44.4085, 169.8513, 4876, 61,  false],
        [1685942091, -43.9192, 171.088,  4876, 60,  false],
        [1685942562, -43.655,  171.7397, 4876, 61,  false],
        [1685942603, -43.6306, 171.8017, 4572, 61,  false],
        [1685942642, -43.6073, 171.8608, 4267, 61,  false],
        [1685942687, -43.5808, 171.928,  3962, 61,  false],
        [1685942725, -43.5597, 171.9814, 3657, 61,  false],
        [1685942771, -43.5352, 172.0432, 3352, 61,  false],
        [1685942815, -43.5118, 172.1022, 3048, 61,  false],
        [1685942864, -43.4861, 172.1666, 2743, 61,  false],
        [1685942914, -43.4599, 172.2323, 2438, 61,  false],
        [1685942963, -43.4345, 172.2956, 2133, 61,  false],
        [1685943014, -43.4079, 172.3621, 1828, 61,  false],
        [1685943036, -43.3962, 172.3912, 1524, 61,  false],
        [1685943040, -43.3942, 172.3966, 1524, 63,  false],
        [1685943048, -43.3906, 172.4071, 1524, 65,  false],
        [1685943065, -43.3833, 172.4303, 1524, 66,  false],
        [1685943111, -43.3634, 172.4929, 1219, 65,  false],
        [1685943116, -43.3614, 172.4989, 914,  65,  false],
        [1685943158, -43.3426, 172.5566, 914,  65,  false]
    ]
}
END
}
