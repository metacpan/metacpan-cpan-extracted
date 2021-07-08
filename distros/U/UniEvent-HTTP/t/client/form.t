use 5.012;
use lib 't/lib';
use MyTest;
use Test::More;

test_catch('[client-form]');

subtest "non-streaming form" => sub {
    my $test = new UE::Test::Async(1);
    my $p    = new MyTest::ClientPair($test->loop);

    $p->server->request_event->add(sub {
        my $req = shift;
        $test->happens;
        ok !$req->chunked, 'non-streaming marker';
        # TODO: need support for form parsing
        like $req->body, qr|name=\"kk\"|s;
        like $req->body, qr|vv|s;

        $req->respond(UE::HTTP::ServerResponse->new({code => 200}));
    });

    my $res = $p->client->get_response({uri => "/", form => ['kk' => 'vv'] });
    is $res->code, 200;
};

subtest "stream form file, embedded-file and field" => sub {
    my $test = new UE::Test::Async(1);
    my $p    = new MyTest::ClientPair($test->loop);

    $p->server->request_event->add(sub {
        my $req = shift;
        $test->happens;
        ok $req->chunked, 'streaming marker';
        # TODO: need support for form parsing
        like $req->body, qr|name=\"kk\"|s;
        like $req->body, qr|vv|s;
        like $req->body, qr|a\.pdf|s;
        like $req->body, qr|\[pdf\]|s;
        like $req->body, qr|application/pdf|s;
        like $req->body, qr|my\.pl|s;
        like $req->body, qr|UE::HTTP::ServerResponse|s, "something from this file";
        like $req->body, qr|text/plain|s;
        $req->respond(UE::HTTP::ServerResponse->new({code => 200}));
    });

    my $in = UE::Streamer::FileInput->new("t/client/form.t");
    $p->client->set_nodelay(1);
    my $res = $p->client->get_response({uri => "/", form => [
        'kk' => 'vv',
        'k2' => ['a.pdf' => '[pdf]', 'application/pdf'],
        'k3' => ['my.pl' => $in, 'text/plain'],
    ]});
    is $res->code, 200;
};

done_testing();
