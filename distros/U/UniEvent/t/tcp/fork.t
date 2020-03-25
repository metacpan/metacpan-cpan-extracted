use strict;
use warnings;
use lib 't/lib'; use MyTest;
use Net::SockAddr;

plan skip_all => "windows doesn't have fork()" if win32();

my $loop = UniEvent::Loop::default_loop();

my $server = UE::Tcp->new($loop);
my $cl;
my $pid;
$server->set_nodelay(1);
$server->bind_addr(SA_LOOPBACK_ANY);
$server->listen(8);
my $sa = $server->sockaddr;

$server->connection_callback(sub {
    my ($srv, $cl, $err) = @_;
    die $err if $err;
    ok(1, "server: connection");
    
    $cl->read_callback(sub {
        my ($handle, $data, $err) = @_;
        die $err if $err;
        is($data, "client_data", "server: read"); #1
        $cl->write("data");
    });
    
    $cl->eof_callback(sub {
        $loop->stop;
    });
});

my $timer = UE::Timer->new($loop);
$timer->event->add(sub {
    $pid = fork();
    unless ($pid) {
        $server->reset();
        
        my $client = UE::Tcp->new();
        $client->set_nodelay(1);
        
        $client->connect_callback(sub {
            my ($handle, $err) = @_;
            die $err if $err;
            ok(1, "child: connect");
            $handle->write("client_data");
        });
        
        $client->read_callback(sub {
            my ($handle, $data, $err) = @_;
            die $err if $err;
            is($data, "data", "child: read");
            $client->shutdown_callback(sub {
                $loop->stop;
            });
            $client->shutdown;
        });
        
        $client->connect_addr($sa);
    }
});
$timer->start(0, 0.01);

$loop->run;

exit unless $pid;
waitpid($pid, 0);
done_testing(4);
