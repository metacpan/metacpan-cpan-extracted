use 5.12.0;
use warnings;
use UniEvent;
use Net::SSLeay;

# This is simple echo client. "Simple" means, that it executes either
# blocking code (reading stdin) or async code (UE loop run). It has
# the drawback, if something happen with server, when client is in blocking
# mode (e.g. disconnect), it will not know about that until it send a line.

# To launch echo client in ssl mode executed something like
# perl examples/echo-client-simple.plx 1234 examples/ca.pem

my ($port, $ca) = @ARGV;
$port //= 9999;

my $client = UniEvent::Tcp->new;
if ($ca) {
  my $client_ctx = Net::SSLeay::CTX_new();
  my $ssl_err = sub {
      die Net::SSLeay::ERR_error_string(Net::SSLeay::ERR_get_error);
  };
  Net::SSLeay::CTX_load_verify_locations($client_ctx, $ca, '') or $ssl_err->();
  $client->use_ssl($client_ctx);
}

my $loop = UniEvent::Loop->default_loop;
say "connecting to $port ...";

$client->connect('127.0.0.1', $port, sub {
    my ($client, $error_code) = @_;
    # will be thrown out of loop run
    die("cannot connect: $error_code\n") if $error_code;
    $loop->stop;
});

$loop->run;
say "connected";

$client->read_callback(sub {
    my ($client, $data, $error_code) = @_;
    die("reading data error: $error_code\n") if $error_code;
    say "[<<] ", $data;
    $loop->stop;
});

my $there_is_more = 1;
$client->eof_callback(sub {
    say "[eof]";
    $there_is_more = 0;
});

while($there_is_more && (my $line = <STDIN>)) {
    chomp($line);
    say "[read] ", $line;
    $client->write($line, sub {
        my ($client, $error_code) = @_;
        die("writing data error: $error_code\n") if $error_code;
        say "[>>] ", $line;
    });
    $loop->run;
}
say "normal exit";