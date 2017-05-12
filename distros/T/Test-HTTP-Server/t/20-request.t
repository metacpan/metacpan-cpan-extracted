#
#
use Test::More tests => 10;
use Test::HTTP::Server;
use POSIX qw(SIGCHLD);
use IO::Socket;
use IO::Select;

my $server = Test::HTTP::Server->new;
alarm 5;

my $uri = $server->uri;
my ($addr) = $uri =~ m{http://(.*?:\d+)/};

my $socket = IO::Socket::INET->new(
    PeerAddr => $addr,
    Proto => 'tcp',
);

my $sel = IO::Select->new( $socket );

ok( !$sel->can_read( 0.1 ), 'nothing to read' );
ok( $sel->can_write( 1 ), 'can write' );

print $socket "GET / HTTP 1.0\r\n\r\n";

ok( $sel->can_read( 1 ), 'can read' );

$/ = undef;
my $resp = <$socket>;

ok( $sel->can_read( 1 ), 'looks closed' );
ok( !<$socket>, 'is closed' );

like( $resp, qr#^HTTP.*NONE$#s, 'got complete response' );

sub handler {
    my ($path, $regex, $name) = @_;
    my $socket = IO::Socket::INET->new(
        PeerAddr => $addr,
        Proto => 'tcp',
    );
    print $socket "GET $path HTTP 1.0\r\n\r\n";
    my $resp = <$socket>;
    like($resp, $regex, $name);
}

handler('/echo/body', qr/^Content-Length: 0/m, 'echo body');
handler('/echo/head', qr=^Content-Length: [0-9]+.*GET /echo/head=ms, 'echo head');
handler('/cookie/3', qr/(?:Set-Cookie: .*\n){3}/, 'cookie');
handler('/repeat/3/Xy', qr/^XyXyXy\z/m, 'repeat');
