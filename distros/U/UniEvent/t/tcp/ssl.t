use 5.012;
use lib 't/lib';
use MyTest;
use Net::SockAddr;
use Net::SSLeay;

test_catch '[tcp-ssl]';

my $SERV_CERT = "t/cert/ca.pem";
my $serv_ctx = Net::SSLeay::CTX_new();
Net::SSLeay::CTX_use_certificate_file($serv_ctx, $SERV_CERT, &Net::SSLeay::FILETYPE_PEM) or sslerr();
Net::SSLeay::CTX_use_PrivateKey_file($serv_ctx, "t/cert/ca.key", &Net::SSLeay::FILETYPE_PEM) or sslerr();
Net::SSLeay::CTX_check_private_key($serv_ctx) or sslerr();

my $client_ctx = Net::SSLeay::CTX_new();
Net::SSLeay::CTX_load_verify_locations($client_ctx, $SERV_CERT, '') or die "something went wrong";

subtest 'ssl doesnt emit empty messages' => sub {
    my $srv = new UE::Tcp;
    $srv->use_ssl($serv_ctx);
    $srv->bind_addr(SOCKADDR_LOOPBACK);
    $srv->listen;
    
    my $cnt = 10;
    my $check = "a" x ($cnt + 1);

    my $sconn;
    $srv->connection_callback(sub {
        $sconn = $_[1];
        $sconn->write("a");
    });

    my $client = new UE::Tcp;
    $client->use_ssl($client_ctx);
    $client->connect_addr($srv->sockaddr);
    
    my $rcv;
    $client->read_callback(sub {
        my ($client, $buf, $err) = @_;
        ok !$err;
        ok $buf;
        $rcv .= $buf;
        
        if ($cnt--) {
            $sconn->write("a");
        } else {
            $client->loop->stop;
        }
    });
    
    $srv->loop->run;
    is $rcv, $check;
};

subtest 'unknown shit' => sub {
    my $srv = new UE::Tcp;
    $srv->use_ssl($serv_ctx);
    $srv->bind_addr(SOCKADDR_LOOPBACK);
    $srv->listen;
    my $sa = $srv->sockaddr;
    
    my @save;
    my $data = 'MAGIC SSL';
    
    $srv->weak(0);
    $srv->connection_callback(sub {
        my (undef, $client, $err) = @_;
        fail $err if $err;
        push @save, $client;
        pass("server: connection");
    
        $client->write($data, sub {
            pass("server: written");
            $client->shutdown;
        });
        
        $client->read_callback(sub {
            my ($h, $str, $err) = @_;
            fail $err if $err;
            is $str, $data, "server: data from client";
        });
        
        $client->eof_callback(sub {
            pass("server: eof");
            $_[0]->loop->stop;
        });
        $srv->weak(1);
    });
    
    my $client = new UE::Tcp;
    $client->use_ssl($client_ctx);
    my $p = new UE::Prepare;
    
    $p->start(sub {
        shift->stop();
        
        $client->read_callback(sub {
            my ($h, $str, $err) = @_;
            fail $err if $err;
            is $str, $data, "client: data from server";
            $h->write($str, sub { pass("client: written") });
        });
        
        $client->eof_callback(sub {
            pass("client: eof");
            shift->shutdown;
        });
        
        $client->connect_callback(sub {
            my (undef, $err) = @_;
            fail $err if $err;
            pass("client: connected");
        });
       
        $client->connect_addr($sa);
    });
    
    $srv->loop->run;
    done_testing(8);
};
done_testing();

sub sslerr () {
    die Net::SSLeay::ERR_error_string(Net::SSLeay::ERR_get_error);
}
