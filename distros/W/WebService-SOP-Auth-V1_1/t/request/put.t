use strict;
use warnings;
use Test::Exception;
use Test::More;
use Test::Pretty;
use URI;
use WebService::SOP::Auth::V1_1::Util qw(create_signature);

my $class = 'WebService::SOP::Auth::V1_1::Request::PUT';

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

        my %query = URI->new("/?" . $req->content)->query_form;
        my $sig   = delete $query{sig};

        is $req->method, 'PUT';
        is_deeply \%query,
            {
            hoge => 'hoge',
            time => 1234,
            };
        is $sig, create_signature(\%query, 'foobar');
    };
};

done_testing;
