
use strict;
use warnings;

use Test::More tests => 2;

use Test::LWP::UserAgent;
use HTTP::Response;
use JSON::Any;

use WebService::Rackspace::CloudFiles;

my $ua = Test::LWP::UserAgent->new;

my $cf = WebService::Rackspace::CloudFiles->new(
    user => 'Wilfred',
    key  => 'deadbeef',
    ua => $ua,
);

$ua->map_response( qr## => sub {
    my $request = shift;

    return HTTP::Response->new(204, 'welcome', [
        'X-Storage-Url' => 'https://foo.com/storage/url',
        'X-Auth-Token'  => 'abracadabra',
        'X-CDN-Management-Url' => 'cdn management url',
    ]); 
});

$cf->_authenticate;

like $ua->last_http_request_sent->uri 
    => qr{\Qauth.api.rackspacecloud.com/v1.0},
    'usa by default';


$cf = WebService::Rackspace::CloudFiles->new(
    user => 'Wilfred',
    key  => 'deadbeef',
    ua => $ua,
    location_url => 'https://my.cloudfile.me/v1.0',
);

$cf->_authenticate;

like $ua->last_http_request_sent->uri 
    => qr{\Qmy.cloudfile.me},
    'location_url';

