use 5.012;
use lib 't/lib';
use MyTest;
use Test::More;
use Net::SSLeay;

variate_catch('[client-redirect]', 'ssl');

subtest "redirect with SSL" => sub {
    my $SERVER_CERT = "t/cert/ca.pem";

    my $serv_ctx = Net::SSLeay::CTX_new_with_method(Net::SSLeay::SSLv23_server_method()) or sslerr();
    Net::SSLeay::CTX_use_certificate_file($serv_ctx, $SERVER_CERT, &Net::SSLeay::FILETYPE_PEM) or sslerr();
    Net::SSLeay::CTX_use_PrivateKey_file($serv_ctx, ($SERVER_CERT =~ s/.pem$/.key/r), &Net::SSLeay::FILETYPE_PEM) or sslerr();
    Net::SSLeay::CTX_check_private_key($serv_ctx) or sslerr();
    Net::SSLeay::CTX_load_verify_locations($serv_ctx, $SERVER_CERT, undef) or sslerr();
    Net::SSLeay::CTX_set_verify($serv_ctx, &Net::SSLeay::VERIFY_PEER | &Net::SSLeay::VERIFY_FAIL_IF_NO_PEER_CERT, undef );
    Net::SSLeay::CTX_set_verify_depth($serv_ctx, 4);

    my $client_ctx = Net::SSLeay::CTX_new_with_method(Net::SSLeay::SSLv23_client_method()) or sslerr();
    Net::SSLeay::CTX_load_verify_locations($client_ctx, $SERVER_CERT, undef) or sslerr();
    Net::SSLeay::CTX_use_certificate_file($client_ctx, 't/cert/01-alice.pem', &Net::SSLeay::FILETYPE_PEM) or sslerr();
    Net::SSLeay::CTX_use_PrivateKey_file($client_ctx, 't/cert/01-alice.key', &Net::SSLeay::FILETYPE_PEM) or sslerr();
    Net::SSLeay::CTX_check_private_key($client_ctx) or sslerr();
    Net::SSLeay::CTX_set_verify($client_ctx, &Net::SSLeay::VERIFY_PEER);
    Net::SSLeay::CTX_set_verify_depth($client_ctx, 4);

    my $server_cfg = { locations => [{host => "127.0.0.1",  ssl_ctx => $serv_ctx}]};

    my $test   = UE::Test::Async->new(["connect", "redirect"]);
    my $server = MyTest::make_server($test->loop, $server_cfg);
    my $client = MyTest::TClient->new($test->loop);

    $client->{sa} = $server->sockaddr;

    $server->request_callback(sub {
        my $req = shift;
        if ($req->uri->path eq "/") {
            $req->redirect("/index");
            note "redirect-1";
        } elsif ($req->uri->path eq "/index") {
            note "redirect-2";
            $req->respond(new UE::HTTP::ServerResponse({code => 200, headers => {h => $req->header("h")}, body => $req->body}));
        }
    });

    $client->connect_callback(sub { $test->happens("connect"); });
    
    my $req = new UE::HTTP::Request({
        uri     => "/",
        headers => {h => 'v'},
        cookies => {c => 'cv'},
        body    => 'b',
        ssl_ctx => $client_ctx,
        redirect_callback => sub {
            my ($req, $res, $ctx) = @_;
            $test->happens("redirect");
            is $res->code, 302;
            is $res->header("location"), "/index";
            is $req->uri->path, "/index";
            is $ctx->uri->path, "/";
            is $req->ssl_ctx, undef;
            is $ctx->ssl_ctx, $client_ctx;
            $req->ssl_ctx($client_ctx);
        },
    });

    my $res = $client->get_response($req);
    is $res->code, 200;

    is $res->header("h"), "v";
    is $res->body, "b";
    is $req->uri->path, "/index";
    is $req->cookie('c'), undef;
};

subtest "do not follow redirections" => sub {
    my $test = new UE::Test::Async();
    my $p    = new MyTest::ClientPair($test->loop);

    $p->server->autorespond(new UE::HTTP::ServerResponse({code => 302, headers => {location => "http://ya.ru"}}));

    my $res = $p->client->get_response({
        uri             => "/",
        follow_redirect => 0,
    });
    is $res->code, 302;
    is $res->header("Location"), "http://ya.ru";
};

subtest "redirection limit" => sub {
    my $test = new UE::Test::Async();
    my $p    = new MyTest::ClientPair($test->loop);

    $p->server->autorespond(new UE::HTTP::ServerResponse({code => 302, headers => {location => "http://ya.ru"}}));

    my $err = $p->client->get_error({
        uri               => "/",
        redirection_limit => 0,
        redirect_callback => sub { fail("should not be called") },
    });
    is $err, UE::HTTP::Error::unexpected_redirect;
};
done_testing();

sub sslerr () {
    die Net::SSLeay::ERR_error_string(Net::SSLeay::ERR_get_error);
}
