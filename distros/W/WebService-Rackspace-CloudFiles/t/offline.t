
use strict;
use warnings;

use Test::More tests => 5;

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

$ua->map_response( qr#v1\.0$# => sub {
    my $request = shift;

    is $request->header('X-Auth-User') => 'Wilfred', 'X-Auth-User passed';
    is $request->header('X-Auth-Key')  => 'deadbeef', 'X-Auth-Key passed';

    return HTTP::Response->new(204, 'welcome', [
        'X-Storage-Url' => 'https://foo.com/storage/url',
        'X-Auth-Token'  => 'abracadabra',
        'X-CDN-Management-Url' => 'cdn management url',
    ]); 
});

$ua->map_response( qr#storage/url# => sub {
    my $request = shift;

    is $request->header('X-Auth-Token') => 'abracadabra', 'X-Auth-Token passed';

    return HTTP::Response->new(200, undef, [],
        JSON::Any->to_json([ { name => 'bar' } ])
    );
});

my @containers = $cf->containers;

is @containers => 1, "only one container";

is $containers[0]->name => 'bar', "container named 'bar'";





