use strict;
use warnings;
use JSON::XS;
use Test::Exception;
use Test::More;
use Test::Pretty;
use WebService::SOP::Auth::V1_1::Util qw(create_signature);

my $class = 'WebService::SOP::Auth::V1_1::Request::PUT_JSON';

use_ok $class;
can_ok $class, 'create_request';

subtest 'Test create_request' => sub {

    subtest 'Fails when `time` is missing' => sub {
        throws_ok {
            $class->create_request('http://hoge/fuga' => { hoge => 'hoge', }, 'hogehoge');
        }
        qr|Missing required parameter|;
    };

    subtest 'Fails when `app_secret` is missing' => sub {
        throws_ok {
            $class->create_request(
                'http://hoge/fuga' => {
                    hoge => 'hoge',
                    time => 1234,
                }
                )
        }
        qr|Missing app_secret|;
    };

    subtest 'Returns a HTTP::Request object when valid' => sub {
        my $req = $class->create_request(
            'http://hoge/fuga' => {
                hoge => 'hoge',
                time => 1234,
            },
            'foobar'
        );

        is $req->method, 'PUT';
        is $req->uri->as_string, 'http://hoge/fuga';
        is $req->headers->header('content-type'), 'application/json';

        my $sig = $req->headers->header('x-sop-sig');

        is $sig, create_signature($req->content, 'foobar');

        is_deeply decode_json($req->content),
            {
            hoge => 'hoge',
            time => 1234,
            };
    };
};

done_testing;
