#!/usr/bin/env perl

use lib 'lib', 't/lib';
use Test::Most;
use WebService::OpenSky::Test qw( set_response );
use Capture::Tiny             qw( capture_stderr );

my $opensky = WebService::OpenSky->new;

my @limited = qw(
  get_states
  get_my_states
);
my @unlimited = qw(
  get_arrivals_by_airport
  get_departures_by_airport
  get_flights_by_aircraft
  get_flights_from_interval
);

foreach my $method ( @limited, @unlimited ) {
    is $opensky->delay_remaining($method), 0, "The $method method should start with no rate limit";
}

my %params = (
    extended => 1,
    bbox     => {
        lomin => -11.141510,
        lamin => 52.257137,
        lomax => 19.607100,
        lamax => 62.890717,
    }
);

set_response( three_vectors() );
my $response = $opensky->get_states(%params);

ok $opensky->delay_remaining('get_states'),     'get_states should have a delay remaining';
ok !$opensky->delay_remaining('get_my_states'), 'get_my_states should not have a delay remaining';
foreach my $method (@unlimited) {
    ok !$opensky->delay_remaining($method), "... and $method should never have a delay remaining";
}

my $stderr = capture_stderr {
    my $response = $opensky->get_states(%params);
};
like $stderr, qr/You have to wait \d+ seconds before you can call get_states again/a, 'Rate limit exceeded message should be printed to STDERR';

done_testing;

sub three_vectors {
    return <<'END';
HTTP/1.1 200 OK
Cache-Control: no-cache, no-store, max-age=0, must-revalidate
Connection: keep-alive
Content-Length: 52570
Content-Type: application/json;charset=UTF-8
Date: Sun, 28 May 2023 08:28:18 GMT
Expires: 0
Pragma: no-cache
Server: nginx/1.17.6
Set-Cookie: XSRF-TOKEN=a103094f-5df1-47e5-9760-31e42c80b7c2; Path=/
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-Rate-Limit-Remaining: 3974
X-XSS-Protection: 1; mode=block

{
	"time":1685262494,
	"states":[
		["511156","SAS67W  ","Estonia",1685262494,1685262494,14.8963,56.5511,11582.4,false,226.44,205.28,0,null,11727.18,"3726",false,0,0],
		["3c6668","DLH9YE  ","Germany",1685262494,1685262494,10.7016,59.3888,7040.88,false,208.9,195.13,9.75,null,7033.26,null,false,0,1],
        ["44028c","EJU42KR ","Austria",1685262494,1685262494,10.9374,52.545,8793.48,false,216.11,88.91,-11.38,null,9044.94,"1000",false,0,4]
    ]
}
END
}
