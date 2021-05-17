use 5.012;
use lib 't/lib';
use MyTest;
use Test::More;
use Protocol::HTTP::Request;

{
    my $req = UE::HTTP::Request->new;
    say "URI=".$req->uri;
}

variate_catch('[client-partial]', 'ssl');

subtest "chunked response receive" => sub {
    my $test = new UE::Test::Async(1);
    my $p    = new MyTest::ClientPair($test->loop);

    my $sres;
    $p->server->request_callback(sub {
        my $req = shift;
        $sres = new UE::HTTP::ServerResponse({code => 200, chunked => 1});
        $req->respond($sres);
    });

    my $count = 10;
    my $res = $p->client->get_response({
        uri => '/',
        partial_callback => sub {
            my ($req, $res, $err) = @_;
            die $err if $err;
    
            if ($count--) {
                $sres->send_chunk("a");
                return;
            }
    
            $sres->send_final_chunk("b");
    
            $req->partial_callback(sub {
                my (undef, $res, $err) = @_;
                die $err if $err;
                return unless $res->is_done;
                $test->happens;
                is $res->body, "aaaaaaaaaab";
            });
        },
    });
    
    is $res->code, 200;
    ok $res->chunked;
    ok $res->is_done;
    is $res->body, "aaaaaaaaaab";
};

subtest "chunked request send" => sub {
    my $test = new UE::Test::Async(1);
    my $p    = new MyTest::ClientPair($test->loop);

    my $sres;
    my $req = new UE::HTTP::Request({
        uri     => '/',
        method  => METHOD_POST,
        chunked => 1,
    });

    my $count = 10;
    $p->server->route_callback(sub {
        my $sreq = shift;
        is $sreq->method, METHOD_POST;
        is $sreq->uri->path, "/";
        $sreq->enable_partial;

        $sreq->partial_callback(sub {
            my ($sreq, $err) = @_;
            die $err if $err;
            if (--$count) {
                $req->send_chunk("a");
                return;
            }
            $req->send_final_chunk("b");

            $sreq->partial_callback(sub {
                my ($sreq, $err) = @_;
                die $err if $err;
                return unless $sreq->is_done;
                ok $sreq->chunked;
                $test->happens;
                is $sreq->body, "aaaaaaaaaab";
                $sreq->respond(new UE::HTTP::ServerResponse({code => 200, body => $sreq->body}));
            });
        });

        $req->send_chunk("a");
    });

    my $res = $p->client->get_response($req);
    is $res->code, 200;
    ok !$res->chunked;
    is $res->body, "aaaaaaaaaab";
};

subtest "100-continue" => sub {
    my $test = new UE::Test::Async(3);
    my $p    = new MyTest::ClientPair($test->loop);

    $p->server->route_callback(sub {
        my $req = shift;
        $req->send_continue for 1..3;
    });
    $p->server->autorespond(new UE::HTTP::ServerResponse({code => 200}));

    my $res = $p->client->get_response({
        uri               => "/",
        headers           => {"Expect" => "100-continue"},
        continue_callback => sub { $test->happens },
    });
    is $res->code, 200;
};

subtest "check that response is the same perl wrapper object on each callback invocation" => sub {
    my $test = new UE::Test::Async(1);
    my $p    = new MyTest::ClientPair($test->loop);

    my $sres;
    $p->server->request_callback(sub {
        my $req = shift;
        $sres = new UE::HTTP::ServerResponse({code => 200, chunked => 1});
        $req->respond($sres);
    });

    my $count = 10;
    my $response;
    my $res = $p->client->get_response({
        uri => '/',
        partial_callback => sub {
            my ($req, $res, $err) = @_;
            die $err if $err;
            
            unless ($response) {
                $response = $res;
                XS::Framework::obj2hv($response);
                $response->{prop} = 123;
                $sres->send_chunk("hello");
                $sres->send_final_chunk;
            } else {
                is $response, $res, "perl wrapper is the same";
                is $res->{prop}, 123, "custom prop ok";
                $test->happens if $res->is_done;
            }
        },
    });
    
    is $res->code, 200;
    is $res->body, "hello";
};

{
    package MyTestResponse;
    use parent 'UniEvent::HTTP::Response';
}

subtest "response factory" => sub {
    my $test = new UE::Test::Async();
    my $p    = new MyTest::ClientPair($test->loop);

    $p->server->autorespond(new UE::HTTP::ServerResponse({code => 200}));

    my $req = UE::HTTP::Request->new({uri => "/"});
    $req->response_factory(sub { MyTestResponse->new });
    my $res = $p->client->get_response($req);
    is $res->code, 200;
    is ref($res), "MyTestResponse";
};

done_testing();