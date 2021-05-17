use 5.012;
use lib 't/lib';
use MyTest;
use Test::More;
use Test::Exception;
use UniEvent::HTTP 'http_request';

variate_catch('[client-pool]', 'ssl');

subtest "reusing connection" => sub {
    my $test = new UE::Test::Async();
    my $pool = new MyTest::TPool($test->loop);
    ok $pool->max_connections > 0;
    my $srv  = MyTest::make_server($test->loop);
    $srv->autorespond(new UE::HTTP::ServerResponse({code => 200}));
    $srv->autorespond(new UE::HTTP::ServerResponse({code => 200}));

    my $uri = "http://".$srv->location.'/';
    my $req = UniEvent::HTTP::Request->new({uri => $uri});
    my $c = $pool->request($req);

    ok $c;
    is $pool->size, 1;
    is $pool->nbusy, 1;

    my $res = $c->await_response($req);
    is $res->code, 200;

    my $req2 = UniEvent::HTTP::Request->new({uri => $uri});
    my $c2 = $pool->request($req);
    is $c, $c2;

    is $pool->size, 1;
    is $pool->nbusy, 1;

    my $res = $c->await_response($req);
    is $res->code, 200;
};

subtest 'http_request' => sub {
    my $test = new UE::Test::Async(1);
    my $srv = MyTest::make_server($test->loop);
    $srv->autorespond(new UE::HTTP::ServerResponse({code => 200, body => "hi"}));

    http_request({
        uri => "http://".$srv->location.'/',
        response_callback => sub {
            my (undef, $res, $err) = @_;
            ok !$err;
            is $res->body, "hi";
            $test->happens;
            $test->loop->stop;
        },
    }, $test->loop);

    my $pool = UE::HTTP::Pool::instance($test->loop);
    is $pool->size, 1;
    is $pool->nbusy, 1;

    $test->run;
};

subtest 'http_request with bad request' => sub {
    dies_ok { http_request(undef) } "undef dies";
    dies_ok { http_request({}) } "request without uri dies";
    dies_ok { http_request({uri => "/"}) } "request with uri without host dies";
};

subtest 'pool with bad request' => sub {
    my $pool = new UE::HTTP::Pool();
    dies_ok { $pool->request(undef) } "undef dies";
    dies_ok { $pool->request({}) } "request without uri dies";
    dies_ok { $pool->request({uri => "/"}) } "request with uri without host dies";
};

done_testing();
