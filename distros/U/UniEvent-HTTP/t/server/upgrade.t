use 5.012;
use lib 't/lib';
use MyTest;
use Test::More;

variate_catch('[server-upgrade]', 'ssl');

subtest "basic upgrade" => sub {
    my $test = new UE::Test::Async(2);
    my $p    = new MyTest::ServerPair($test->loop);
    
    my $req;

    $p->server->request_callback(sub {
        $req = shift;
        $test->loop->stop;
    });

    $p->conn->write(
        "GET / HTTP/1.1\r\n".
        "Connection: upgrade\r\n".
        "Upgrade: my videocard\r\n".
        "\r\n"
    );
    
    $test->run;
    ok $req;
    is $req->headers->{upgrade}, "my videocard";
    
    my $s = $req->upgrade;
    ok $s;
    
    $p->conn->read_callback(sub {
        $test->happens;
        is $_[1], "hello";
        $test->loop->stop;
    });

    $s->write("hello");
    $test->run;

    $s->read_callback(sub {
        $test->happens;
        is $_[1], "world";
        $test->loop->stop;
    });

    $p->conn->write("world");
    $test->run;
};

done_testing();
