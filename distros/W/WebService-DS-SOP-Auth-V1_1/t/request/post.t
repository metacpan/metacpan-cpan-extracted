use strict;
use warnings;
use Test::Exception;
use Test::More;
use URI;
use WebService::DS::SOP::Auth::V1_1::Request::POST;

my $class = 'WebService::DS::SOP::Auth::V1_1::Request::POST';

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
    my $uri = URI->new('http://hoge/post');
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
    is $req->headers->header('content-type'), 'application/x-www-form-urlencoded';

    isa_ok $req->uri, 'URI';
    is $req->uri->as_string, 'http://hoge/post';

    {
        my $uri = URI->new('/?'. $req->content);
        my %q = $uri->query_form;

        is_deeply \%q, {
            aaa => 'aaa',
            bbb => 'bbb',
            sig => '40499603a4a5e8d4139817e415f637a180a7c18c1a2ab03aa5b296d7756818f6',
            time => '1234',
        };
    };
};

done_testing;
