use 5.12.0;
use warnings;
use UniEvent;
use Net::SSLeay;

# To launch echo server in ssl mode executed something like
# perl examples/echo-server.plx 1234 examples/ca.pem examples/ca.key

# non-ssl-clients can be tested via:
# - telnet 127.0.0.1 1234
# - nc 127.0.0.1 1234
# - perl examples/echo-client-simple.plx 1234
#
# ssl-clients can be tested via:
# - openssl s_client -connect 127.0.0.1:1234
# - perl examples/echo-client-simple.plx 1234 examples/ca.pem

my ($port, $ca, $key) = @ARGV;
$port //= 9999;

my $server = UniEvent::Tcp->new;
if ($ca && $key) {
    require Net::SSLeay;
    my $ssl_err = sub {
        die Net::SSLeay::ERR_error_string(Net::SSLeay::ERR_get_error);
    };
    my $serv_ctx = Net::SSLeay::CTX_new();
    Net::SSLeay::CTX_use_certificate_file($serv_ctx, $ca, &Net::SSLeay::FILETYPE_PEM) or $ssl_err->();
    Net::SSLeay::CTX_use_PrivateKey_file($serv_ctx, $key, &Net::SSLeay::FILETYPE_PEM) or $ssl_err->();
    Net::SSLeay::CTX_check_private_key($serv_ctx) or $ssl_err->();
    $server->use_ssl($serv_ctx);
}

$server->bind('127.0.0.1', $port);
$server->listen;

say "$$ listening on port $port";

my %clients;

$server->connection_callback(sub {
    my ($server, $client, $error_code) = @_;
    say "client ", $client->sockaddr, "::", $client->peeraddr, " has connected";
    return say "... but with error: $error_code" if $error_code;

    $client->eof_callback(sub {
        my $client = shift;
        say "eof happend with client ($client) ", $client->sockaddr; # xxx
        delete $clients{$client->sockaddr};
    });
    $client->read_callback(sub {
        my ($client, $data, $error_code) = @_;
        if ($error_code) {
            say "error happen with client ", $client->sockaddr, " :: $error_code";
            delete $clients{$client->sockaddr};
        }
        $client->write($data);
        say "echoed ", length($data), " bytes back to the ",  $client->sockaddr;
    });
    $clients{$client->sockaddr} = $client;
});


UniEvent::Loop->default_loop->run;
