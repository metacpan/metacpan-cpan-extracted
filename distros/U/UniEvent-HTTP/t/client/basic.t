use 5.012;
use lib 't/lib';
use MyTest;
use Test::More;
use Test::Exception;

variate_catch('[client-basic]', 'ssl');

subtest "trivial get" => sub {
    my $test = new UE::Test::Async(1);
    my $p    = new MyTest::ClientPair($test->loop);
    $p->server->enable_echo;

    my $sa = $p->server->sockaddr;
    $p->server->request_event->add(sub {
        my $req = shift;
        $test->happens;
        is $req->header("host"), $sa->ip . ':' . $sa->port;
    });

    my $res = $p->client->get_response({uri => "/", headers => {"Hello" => "world"}});
    is $res->code, 200;
    is $res->http_version, 11;
    is $res->header("HellO"), "world";
};

subtest "timeout" => sub {
    my $test = new UE::Test::Async();
    my $p    = new MyTest::ClientPair($test->loop);

    my $err = $p->client->get_error({uri => "/", timeout => 0.005});
    is $err, XS::STL::errc::timed_out;
};

subtest 'bad request' => sub {
    my $client = new UE::HTTP::Client();
    dies_ok { $client->request(undef) } "undef dies";
    dies_ok { $client->request({}) } "request without uri dies";
    dies_ok { $client->request({uri => "/"}) } "request with uri without host dies";
};


subtest "compression" => sub {
    my $test = new UE::Test::Async(1);
    my $p    = new MyTest::ClientPair($test->loop);
    $p->server->enable_echo;

    my $sa = $p->server->sockaddr;
    $p->server->request_event->add(sub {
        my $req = shift;
        $test->happens;
        is $req->header("host"), $sa->ip . ':' . $sa->port;
    });

    my $res = $p->client->get_response({uri => "/", body => "hello-world", compressed => Protocol::HTTP::Compression::gzip});
    is $res->code, 200;
    is $res->http_version, 11;
};

done_testing();
