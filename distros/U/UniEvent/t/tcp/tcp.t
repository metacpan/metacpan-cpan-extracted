use 5.012;
use lib 't/lib';
use MyTest;

subtest "run in order" => sub {
    my $test = UE::Test::Async->new(0, 2);
    
    my $h = UE::Tcp->new($test->loop);
    my $s = "";
    $h->run_in_order(sub { $s .=  "1" });
    is $s, "1";

    my $server = UE::Tcp->new($test->loop);
    $server->bind("127.0.0.1", 0);
    $server->listen(10000);
    my $sa = $server->sockaddr;

    $h->connect_addr($sa);
    $h->connect_callback(sub {
        is $s, "1";
    });

    $h->run_in_order(sub { $s .= "2" });

    $h->write("123");
    $h->write_callback(sub {
        is $s, "12";
    });

    $h->run_in_order(sub { $s .= "3" });

    $h->shutdown;
    $h->shutdown_callback(sub {
        is $s, "123";
        $test->loop->stop;
    });

    is $s, "1";
    $test->run;
    is $s, "123";
};

done_testing();
