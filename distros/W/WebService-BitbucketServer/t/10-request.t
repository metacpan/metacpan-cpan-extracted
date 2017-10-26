#!perl

use warnings;
use strict;

use lib 't/lib';

use WebService::BitbucketServer;
use HTTP::AnyUA;
use Test::More tests => 4;

HTTP::AnyUA->register_backend(Mock => '+MockBackend');

sub get_request {
    my $api = WebService::BitbucketServer->new(
        base_url    => 'https://stash.example.com/',
        username    => 'bob',
        password    => 'secret',
        ua          => 'Mock',
        @_,
    );

    my $backend = $api->any_ua->backend;

    my $res = $api->call(method => 'GET', url => 'api/1.0/application-properties');
    my $req = ($backend->requests)[-1];

    return $req;
}

my $req1 = get_request();
is $req1->[0], 'GET', 'request has the correct method';
is $req1->[1], 'https://stash.example.com/rest/api/1.0/application-properties', 'request has the correct url';
is $req1->[2]->{headers}{authorization}, 'Basic Ym9iOnNlY3JldA==', 'request has the correct authorization';

my $req2 = get_request(path => 'foo');
is $req2->[1], 'https://stash.example.com/foo/api/1.0/application-properties', 'request has the correct url';

