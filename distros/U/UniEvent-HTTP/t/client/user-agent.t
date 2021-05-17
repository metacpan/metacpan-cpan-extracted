use 5.012;
use lib 't/lib';
use MyTest;
use Test::More;

variate_catch('[user-agent]', 'ssl');

subtest "simple UA usage" => sub {
    my $test = UE::Test::Async->new;
    my $srv  = MyTest::make_server($test->loop);

    $srv->request_event->add(sub {
        my $req = shift;
        my $res = UE::HTTP::ServerResponse->new({code => 200, cookies => { sid => { value => '123' }}});
        my $headers = $req->headers;
        if (my $ua = $headers->{'user-agent'}) {
            $res->header('UA', $ua);
        }
        $req->respond($res);
    });
    my $uri = URI::XS->new($srv->uri);


    my $ua = MyTest::TUserAgent->new({}, $test->loop);
    $ua->identity('test-ua');
    my $req = UniEvent::HTTP::Request->new({ uri  => $uri });

    is scalar(keys %{ $ua->cookie_jar->all_cookies }), 0;
    my $c = $ua->request($req);
    my $res = $c->await_response($req);
    is $res->code, 200;
    is scalar(keys %{ $ua->cookie_jar->all_cookies }), 1;
    is $res->header('UA'), 'test-ua';

    $ua->identity(undef);
    my $req2 = UniEvent::HTTP::Request->new({ uri  => $uri });
    my $res2 = $ua->request($req2)->await_response($req2);
    is $res2->code, 200;
    is $res2->header('UA'), undef;

    my $ua2 = MyTest::TUserAgent->new({serialized => $ua->to_string(1)}, $test->loop);
    is_deeply $ua2->cookie_jar->to_string(1), $ua->to_string(1);


};

done_testing;
