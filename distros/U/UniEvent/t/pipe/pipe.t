use 5.012;
use warnings;
use Socket;
use lib 't/lib'; use MyTest;

use constant PIPE_PATH => MyTest::pipe "pipe1";

subtest 'client-server' => sub {
    my $l = UniEvent::Loop->new;
    
    my $srv = new UniEvent::Pipe($l);
    $srv->bind(PIPE_PATH);
    $srv->listen();
    
    like($srv->sockname, qr#pipe1#);
    is $srv->peername, undef;
    
    my $conn;
    
    $srv->connection_callback(sub {
        $conn = $_[1];
        #diag "Connection";
        $conn->eof_callback(sub {
            #diag "EOF callback started";
            $srv->clear;
        });
        #diag "Issuing shutdown() now!";
        $conn->shutdown();
    });
    
    my $p = new UniEvent::Prepare($l);
    $p->start(sub {
        #diag "create client";
	    my $client = new UniEvent::Pipe($l);
	    $client->connect(PIPE_PATH, sub {
	        my ($client, $err) = @_;
	        #diag "on_connect";
            is $client->sockname, "";
	        is($client->peername, $srv->sockname);
            die $err if $err;
	    });
	    $client->shutdown(sub {
            #diag "client on_shutdown";
            die $_[1] if $_[1];
        });
	    $p->stop();
	});
	
    $l->run();
    
    #diag "That's o'kay";
};

subtest 'open connected socket' => sub {
    my $l = UniEvent::Loop->new;

    my $srv = new UniEvent::Pipe($l);
    $srv->bind(PIPE_PATH);
    $srv->listen();
    
    $srv->connection_callback(sub {
        my ($srv, $conn, $err) = @_;
        $conn->write("epta");
        $conn->shutdown();
    });
    
    socket my $sock, AF_UNIX, SOCK_STREAM, 0;
    my $sa = pack_sockaddr_un PIPE_PATH;
    connect($sock, $sa) or die "$!";
    
    my $client = new UniEvent::Pipe($l);
    $client->open($sock);
    close($sock);
    undef $sock;
    
    my $res;
    $client->read_callback(sub {
        my $h = shift;
        $res = shift;
        $h->clear;
        $srv->clear;
    });
    
    $l->run;
    
    is $res, "epta";
} unless win32();

done_testing();