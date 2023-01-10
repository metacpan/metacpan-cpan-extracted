use strict;
use warnings;
use Test::Exception;
use Test::More;
use URI;
use WebService::DS::SOP::Auth::V1_1::Request::GET;

my $class = 'WebService::DS::SOP::Auth::V1_1::Request::GET';

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

    throws_ok {
        $class->create_request(
            '/hoge', { hoge => 'hoge', time => '1234' }, 'hogehoge',
        )
    } qr|"query_form"|;
};

subtest 'Test create_request OK' => sub {
    my $uri = URI->new('http://hoge/get');
    my $params = {
        aaa => 'aaa',
        bbb => 'bbb',
        time => '1234',
    };

    my $req = $class->create_request(
        $uri, $params, 'hogehoge',
    );

    isa_ok $req, 'HTTP::Request';
    is $req->method, 'GET';

    isa_ok $req->uri, 'URI';
    is $req->uri->host, 'hoge';
    is $req->uri->path, '/get';

    {
        my %params = $req->uri->query_form;

        is_deeply \%params, {
            aaa => 'aaa',
            bbb => 'bbb',
            sig => '40499603a4a5e8d4139817e415f637a180a7c18c1a2ab03aa5b296d7756818f6',
            time => '1234',
        };
    };
};

done_testing;
