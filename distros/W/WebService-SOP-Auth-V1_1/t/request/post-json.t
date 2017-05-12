use strict;
use warnings;
use JSON::XS qw(decode_json);
use Test::Exception;
use Test::Mock::Guard;
use Test::More;
use Test::Pretty;
use URI;
use WebService::SOP::Auth::V1_1::Request::POST_JSON;

my $class = 'WebService::SOP::Auth::V1_1::Request::POST_JSON';

subtest 'Test create_request fail' => sub {
    my $uri = URI->new('http://hoge/get');

    throws_ok {
        $class->create_request(
            $uri, undef, 'hogehoge',
        )
    } qr|Missing required parameter|;

    throws_ok {
        $class->create_request(
            $uri, { hoge => 'hoge' }, 'hogehoge',
        )
    } qr|Missing required parameter|;

    throws_ok {
        $class->create_request(
            $uri, { hoge => 'hoge', time => '1234' }, '',
        )
    } qr|Missing app_secret|;
};

subtest 'Test create_request OK' => sub {
    my $guard = mock_guard(
        $class => {
            create_signature => sub {
                my ($content, $app_secret) = @_;
                my $data = decode_json($content);

                is_deeply $data, {
                    aaa => 'aaa',
                    bbb => 'bbb',
                    time => '1234',
                };
                is $app_secret, 'hogehoge';

                'hoge-signature';
            },
        },
    );

    my $uri = URI->new('http://hoge/post_json');
    my $params = {
        aaa => 'aaa',
        bbb => 'bbb',
        time => '1234',
    };

    my $req = $class->create_request(
        $uri => $params, 'hogehoge',
    );

    isa_ok $req, 'HTTP::Request';
    is $req->method, 'POST';

    is $req->headers->header('content-type'), 'application/json';
    is $req->headers->header('x-sop-sig'), 'hoge-signature';

    isa_ok $req->uri, 'URI';
    is $req->uri->as_string, 'http://hoge/post_json';

    {
        my $data = decode_json($req->content);

        is_deeply $data, {
            aaa => 'aaa',
            bbb => 'bbb',
            time => '1234',
        };
    };
};

done_testing;
