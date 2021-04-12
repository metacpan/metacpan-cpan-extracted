use 5.12.0;
use warnings;
use UniEvent;
use Net::SSLeay;

# This is async echo client. Comparing to "simple" client, it is almost
# completely non-blocking, as it reads in non-blocking mode from console
# and write and reads non-blocking mode over TCP/SSL stream.
# The "almost" means, that output to console (i.e. "say" instructions)
# can still block. "say" is used for simplicity.

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
});

$client->eof_callback(sub {
    say "[eof,remote]";
    $loop->stop;
});

my $tty_in = UniEvent::Tty->new(\*STDIN, $loop);
$tty_in->read_start();

my $line = '';
$tty_in->read_callback(sub {
    my ($tty_in, $data, $error_code) = @_;
    die("reading data error: $error_code\n") if $error_code;
    $line .= $data;
    return unless $line =~ s/((.+)\n)//;
    my $out = $1;
    chomp($out);
    $client->write($out, sub {
        my ($client, $error_code) = @_;
        die("writing data error: $error_code\n") if $error_code;
        say "[>>] ", $out;
    })
});

$tty_in->eof_callback(sub {
    say "[eof,tty]";
    $loop->stop;
});


$loop->run;

say "normal exit";