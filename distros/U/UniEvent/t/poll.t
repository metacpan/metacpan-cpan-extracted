use 5.012;
use warnings;
use lib 't/lib'; use MyTest;
use Socket;
use UniEvent::Poll;

my $l = UE::Loop->default_loop;

my $srv = UE::Tcp->new;
$srv->bind("127.0.0.1", 0);
$srv->listen;
$srv->connection_callback(sub {
    my ($srv, $client) = @_;
    $client->write("hi");
});

socket(my $fh, AF_INET, SOCK_STREAM, (getprotobyname('tcp'))[2]) or die "$!";
connect($fh, $srv->sockaddr->get) or die $!;

subtest 'start/stop/reset' => sub {
    my $h = new UE::Poll($fh);
    is $h->type, UE::Poll::TYPE, 'type ok';
    
    my $i = 0;
    $h->callback(sub {
        my ($h, $events, $err) = @_;
        is $events, READABLE;
        $i++;
        $l->stop;
    });
    $h->start(READABLE);
    
    $l->run;
    is $i, 1;
    
    $h->stop;
    $l->run_nowait for 1..10;
    is $i, 1;
    
    $h->start(READABLE);
    $l->run;
    is $i, 2;
    
    $h->reset;
    is $i, 2;
};

subtest 'call_now' => sub {
    my $h = new UE::Poll($fh);
    my $i = 0;
    $h->event->add(sub { $i++ });
    $h->call_now(READABLE) for 1..5;
    is $i, 5;
};

subtest 'event listener' => sub {
    no warnings 'once';
    my $cnt;
    *MyLst::on_poll = sub { is $_[2], READABLE; $cnt += 10 };
    my $h = new UE::Poll($fh);
    $h->event_listener(bless {}, 'MyLst');
    $h->callback(sub { $cnt++ });
    
    $h->call_now(READABLE);
    is $cnt, 11, "listener&event called";
};

done_testing();
