use 5.012;
use lib 't/lib';
use MyTest;
use Test::More;
use Test::Exception;
use Protocol::HTTP::Request;

variate_catch('[server-basic]', 'ssl');

subtest 'simple request/response' => sub {
    my $test = new UE::Test::Async(1);
    my $p    = new MyTest::ServerPair($test->loop);
    
    $p->server->request_callback(sub {
        my $req = shift;
        $test->happens;
        
        isa_ok($req, 'UniEvent::HTTP::ServerRequest');
        is $req->method, METHOD_POST;
        ok $req->is_done;
        is $req->body, "epta nah";
        ok !$req->chunked;
        is $req->headers->{"content-length"}, 8;
        is $req->header("content-lengTH"), 8;
        
        $req->respond(new UE::HTTP::ServerResponse({
            code    => 200,
            headers => {a => 1, b => 2},
            body    => "sosi epta",
        }));
    });
    
    my $res = $p->get_response(
        "POST / HTTP/1.1\r\n".
        "Content-length: 8\r\n".
        "\r\n".
        "epta nah"
    );
    is $res->code, 200;
    is $res->header("a"), 1;
    is $res->header("b"), 2;
    is $res->body, "sosi epta";
};

subtest "parsing error" => sub {
    my $test = new UE::Test::Async(1);
    my $p    = new MyTest::ServerPair($test->loop);

    $p->server->error_callback(sub {
        my ($req, $err) = @_;
        $test->happens;
        is $req->header("host"), "epta.ru";
        is $err, Protocol::HTTP::Error::lexical_error;
        $req->respond(new UE::HTTP::ServerResponse({code => 404}));
    });

    $p->server->request_callback(\&fail_cb);

    my $res = $p->get_response(
        "GET / HTTP/1.1\r\n".
        "Host: epta.ru\r\n".
        "Transfer-Encoding: chunked\r\n".
        "\r\n".
        "something not looking like chunk"
    );
    is $res->code, 404;
};

subtest "drop event" => sub {
    my $test = new UE::Test::Async(2);
    my $p    = new MyTest::ServerPair($test->loop);

    $p->server->autorespond(new UE::HTTP::ServerResponse({code => 200, chunked => 1}));
    
    $p->server->request_callback(sub {
        my $req = shift;
        $test->happens;
        $req->drop_callback(sub {
            my ($req, $err) = @_;
            $test->happens;
            is $err, XS::STL::errc::connection_reset;
            is $req->header("host"), "epta.ru";
            $test->loop->stop();
        });
        $p->conn->disconnect;
    });

    $p->conn->write(
        "GET / HTTP/1.1\r\n".
        "Host: epta.ru\r\n".
        "\r\n"
    );

    $test->run;
};

subtest "max headers size" => sub {
    my $test = new UE::Test::Async();
    my $p    = new MyTest::ServerPair($test->loop, {max_headers_size => 14});
    $p->server->autorespond(new UE::HTTP::ServerResponse({code => 200}));

    my $res = $p->get_response(
        "GET / HTTP/1.1\r\n".
        "Header: value\r\n". # len=15
        "\r\n"
    );
    is $res->code, 400;
};

subtest "max body size" => sub {
    my $test = new UE::Test::Async();
    my $p    = new MyTest::ServerPair($test->loop, {max_body_size => 9});
    $p->server->autorespond(new UE::HTTP::ServerResponse({code => 200}));

    my $res = $p->get_response(
        "GET / HTTP/1.1\r\n".
        "Content-Length: 10\r\n".
        "\r\n".
        "0123456789"
    );
    is $res->code, 400;
};

subtest "bad response argument" => sub {
    my $test = new UE::Test::Async();
    my $p    = new MyTest::ServerPair($test->loop);
    
    $p->server->request_callback(sub {
        my $req = shift;
        dies_ok { $req->respond(undef) } "undef dies";
        $req->respond(new UE::HTTP::ServerResponse({code => 200}));
    });

    my $res = $p->get_response("GET / HTTP/1.1\r\n\r\n");
    is $res->code, 200;
};

done_testing();
