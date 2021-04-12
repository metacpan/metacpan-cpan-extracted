use 5.012;
use lib 't/lib';
use MyTest;
use Net::SockAddr;
use XS::Framework;

test_catch '[tcp-connect]';

my $loop = UniEvent::Loop->default_loop;

subtest 'connect-diconnect' => sub {
    my $s = new UniEvent::Tcp;
    $s->connection_factory(sub {
        my $client = shift;
        XS::Framework::obj2hv($client);
        $client->{my_data} = 'sample data';
        return $client;
    });
    $s->bind_addr(SOCKADDR_LOOPBACK);
    $s->listen;
    $s->connection_callback(sub {
        my ($server, $client) = @_;
        is $client->{my_data}, 'sample data';
    });
    my $sa = $s->sockaddr;

    my $cl = new UniEvent::Tcp;
    $cl->connect_addr($sa, sub {
        my ($handler, $err) = @_;
        fail $err if $err;
        pass "first connected";
    });
    $cl->write('1');
    $cl->disconnect;
    $cl->connect_addr($sa, sub {
        my ($handler, $err) = @_;
        fail $err if $err;
        pass "second connected";
        $loop->stop;
    });

    $loop->update_time;
    $loop->run;
    $loop->run_nowait(); # sometimes connection_callback on server is called after connect_callback on client

    done_testing(4);
};

done_testing();

