#!perl

use warnings;
use strict;

use lib 't/lib';

use WebService::BitbucketServer;
use HTTP::AnyUA;
use Test::More tests => 11;

HTTP::AnyUA->register_backend(Mock => '+MockBackend');

my $api = WebService::BitbucketServer->new(
    base_url    => 'https://stash.example.com/',
    username    => 'bob',
    password    => 'secret',
    ua          => 'Mock',
);

my $backend = $api->any_ua->backend;
$backend->response({
    'content'   => '{"version":"4.8.5","buildNumber":"4008005","buildDate":"1471843790056","displayName":"Bitbucket"}',
    'headers'   => {
        'cache-control'             => 'no-cache, no-transform',
        'connection'                => 'close',
        'content-type'              => 'application/json;charset=UTF-8',
        'date'                      => 'Tue, 24 Oct 2017 03:27:13 GMT',
        'server'                    => 'Apache-Coyote/1.1',
        'transfer-encoding'         => 'chunked',
        'vary'                      => 'X-AUSERNAME,Accept-Encoding',
        'x-arequestid'              => '@blahblah',
        'x-asen'                    => 'SEN-1234567',
        'x-auserid'                 => '123',
        'x-ausername'               => 'bob',
        'x-content-type-options'    => 'nosniff',
    },
    'protocol'  => 'HTTP/1.1',
    'reason'    => 'OK',
    'status'    => '200',
    'success'   => 1,
    'url'       => 'https://stash.example.com/rest/api/1.0/application-properties',
});

my $response = $api->core->get_application_properties;

is $response->json, $api->json, 'response shares json object with context';
is $response->context, $api, 'context object is correct';
ok $response->is_success, 'response is a success';
ok !$response->error, 'response has no error';
ok !$response->is_paged, 'response is not paged';
is $response->page_info, undef, 'page info is not defined';
is $response->next, undef, 'next page is not defined';
is $response->status, '200', 'response status is correct';
is_deeply $response->raw, $backend->response, 'raw response is correct';
is_deeply $response->request_args, {
    method => 'GET',
    url => 'api/1.0/application-properties',
}, 'request args are correct';
is_deeply $response->data, {
    version => '4.8.5',
    buildNumber => '4008005',
    buildDate => '1471843790056',
    displayName => 'Bitbucket',
}, 'response data parses correctly';

