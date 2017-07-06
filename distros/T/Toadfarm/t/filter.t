use lib '.';
use Mojo::Base -strict;
use Mojo::IOLoop;
use Mojo::Server::Daemon;
use Test::More;

BEGIN { $ENV{MOJO_MODE} = 'production' }

plan skip_all => 'TEST_LIVE=1 is required' unless $ENV{TEST_LIVE} or $ENV{USER} eq 'jhthorsen';
plan skip_all => 'MOJO_CONFIG /tmp/filter.t.conf exists' if -s $ENV{MOJO_CONFIG};

my $allowed = Mojo::IOLoop::Server->generate_port;
my $denied  = Mojo::IOLoop::Server->generate_port;

{
  use Toadfarm -test;
  mount 't::lib::App' => {remote_address => '127.0.0.1', local_port => $allowed};
  start;
}

my $server = Mojo::Server::Daemon->new(app => app, silent => 1);
my ($bytes, $client);

$server->listen(["http://*:$allowed", "http://*:$denied"])->start;

$bytes = "";
$client = client("127.0.0.1", $denied);
Mojo::IOLoop->start;
like $bytes, qr{404 Not Found}, 'Invalid port';

$bytes = "";
$client = client("127.0.0.1", $allowed);
Mojo::IOLoop->start;
like $bytes, qr{Dummy}, 'Valid port and address';

$bytes = "";
$client = client(local_address(), $allowed);
Mojo::IOLoop->start;
like $bytes, qr{404 Not Found}, 'Invalid address';

done_testing;

sub client {
  diag "address $_[0], port: $_[1]";
  Mojo::IOLoop->client(
    {address => $_[0], port => $_[1]},
    sub {
      my ($loop, $err, $stream) = @_;
      BAIL_OUT $err if $err;
      $stream->on(read => sub { $bytes .= $_[1]; Mojo::IOLoop->stop if 20 < length $bytes; });
      $stream->write("GET /dummy HTTP/1.1\x0d\x0a\x0d\x0a");
    }
  );
}

# ugly
sub local_address {
  open my $IFCONFIG, '-|', 'ifconfig -a';
  while (<$IFCONFIG>) {
    return $1 if /inet(?:\saddr)?\D+(\d\S+)/ and $1 ne '127.0.0.1';
  }
  die 'Could not find local inet addr.';
}
