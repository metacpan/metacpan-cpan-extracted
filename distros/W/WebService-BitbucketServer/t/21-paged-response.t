#!perl

use warnings;
use strict;

use lib 't/lib';

use WebService::BitbucketServer;
use HTTP::AnyUA;
use Test::More tests => 10;

HTTP::AnyUA->register_backend(Mock => '+MockBackend');

my $api = WebService::BitbucketServer->new(
    base_url    => 'https://stash.example.com/',
    username    => 'bob',
    password    => 'secret',
    ua          => 'Mock',
);

my $backend = $api->any_ua->backend;
$backend->response({
    'content'   => '{"size":2,"limit":15,"isLastPage":true,"values":[{"slug":"myrepo","id":1,"name":"myrepo","scmId":"git","state":"AVAILABLE","statusMessage":"Available","forkable":true,"project":{"key":"~BOB","id":10,"name":"Bob Person","type":"PERSONAL","owner":{"name":"bob","emailAddress":"bob@example.com","id":30,"displayName":"Bob Person","active":true,"slug":"bob","type":"NORMAL","links":{"self":[{"href":"https://stash.example.com/users/bob"}]}},"links":{"self":[{"href":"https://stash.example.com/users/bob"}]}},"public":true,"links":{"clone":[{"href":"ssh://git@stash.example.com:7999/~bob/myrepo.git","name":"ssh"},{"href":"https://bob@stash.example.com/scm/~bob/myrepo.git","name":"http"}],"self":[{"href":"https://stash.example.com/users/bob/repos/myrepo/browse"}]}},{"slug":"orgrepo","id":2,"name":"orgrepo","scmId":"git","state":"AVAILABLE","statusMessage":"Available","forkable":true,"project":{"key":"ORG","id":11,"name":"Organization Project","description":"Repositories for our organization","public":false,"type":"NORMAL","links":{"self":[{"href":"https://stash.example.com/projects/ORG"}]}},"public":false,"links":{"clone":[{"href":"https://bob@stash.example.com/scm/org/orgrepo.git","name":"http"},{"href":"ssh://git@stash.example.com:7999/org/orgrepo.git","name":"ssh"}],"self":[{"href":"https://stash.example.com/projects/ORG/repos/orgrepo/browse"}]}}],"start":0}',
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
    'url'       => 'https://stash.example.com/rest/api/1.0/profile/recent/repos',
});

my $response = $api->call(method => 'GET', url => 'api/1.0/profile/recent/repos');

is $response->context, $api, 'context object is correct';
ok $response->is_success, 'response is a success';
ok !$response->error, 'response has no error';
ok $response->is_paged, 'response is paged';
is_deeply $response->page_info, {
    is_last_page    => \1,
    limit           => 15,
    start           => 0,
    size            => 2,
    next_page_start => undef,
    filter          => undef,
}, 'page info is correct';
is $response->next, undef, 'next page is not defined';
is $response->status, '200', 'response status is correct';
is_deeply $response->raw, $backend->response, 'raw response is correct';
is_deeply $response->request_args, {
    method => 'GET',
    url => 'api/1.0/profile/recent/repos',
}, 'request args are correct';
my $expected = [
          {
            'forkable' => bless( do{\(my $o = 1)}, 'JSON::PP::Boolean' ),
            'id' => 1,
            'scmId' => 'git',
            'name' => 'myrepo',
            'project' => {
                           'id' => 10,
                           'key' => '~BOB',
                           'links' => {
                                        'self' => [
                                                    {
                                                      'href' => 'https://stash.example.com/users/bob'
                                                    }
                                                  ]
                                      },
                           'owner' => {
                                        'emailAddress' => 'bob@example.com',
                                        'slug' => 'bob',
                                        'type' => 'NORMAL',
                                        'active' => bless( do{\(my $o = 1)}, 'JSON::PP::Boolean' ),
                                        'id' => 30,
                                        'displayName' => 'Bob Person',
                                        'links' => {
                                                     'self' => [
                                                                 {
                                                                   'href' => 'https://stash.example.com/users/bob'
                                                                 }
                                                               ]
                                                   },
                                        'name' => 'bob'
                                      },
                           'type' => 'PERSONAL',
                           'name' => 'Bob Person'
                         },
            'state' => 'AVAILABLE',
            'public' => bless( do{\(my $o = 1)}, 'JSON::PP::Boolean' ),
            'links' => {
                         'self' => [
                                     {
                                       'href' => 'https://stash.example.com/users/bob/repos/myrepo/browse'
                                     }
                                   ],
                         'clone' => [
                                      {
                                        'href' => 'ssh://git@stash.example.com:7999/~bob/myrepo.git',
                                        'name' => 'ssh'
                                      },
                                      {
                                        'href' => 'https://bob@stash.example.com/scm/~bob/myrepo.git',
                                        'name' => 'http'
                                      }
                                    ]
                       },
            'statusMessage' => 'Available',
            'slug' => 'myrepo'
          },
          {
            'slug' => 'orgrepo',
            'forkable' => bless( do{\(my $o = 1)}, 'JSON::PP::Boolean' ),
            'id' => 2,
            'scmId' => 'git',
            'state' => 'AVAILABLE',
            'project' => {
                           'public' => bless( do{\(my $o = 0)}, 'JSON::PP::Boolean' ),
                           'links' => {
                                        'self' => [
                                                    {
                                                      'href' => 'https://stash.example.com/projects/ORG'
                                                    }
                                                  ]
                                      },
                           'name' => 'Organization Project',
                           'type' => 'NORMAL',
                           'description' => 'Repositories for our organization',
                           'id' => 11,
                           'key' => 'ORG'
                         },
            'name' => 'orgrepo',
            'links' => {
                         'clone' => [
                                      {
                                        'name' => 'http',
                                        'href' => 'https://bob@stash.example.com/scm/org/orgrepo.git'
                                      },
                                      {
                                        'href' => 'ssh://git@stash.example.com:7999/org/orgrepo.git',
                                        'name' => 'ssh'
                                      }
                                    ],
                         'self' => [
                                     {
                                       'href' => 'https://stash.example.com/projects/ORG/repos/orgrepo/browse'
                                     }
                                   ]
                       },
            'statusMessage' => 'Available',
            'public' => bless( do{\(my $o = 0)}, 'JSON::PP::Boolean' )
          }
        ];
is_deeply $response->data, $expected, 'response data parses correctly';

