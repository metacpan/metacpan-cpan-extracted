#
#
use Test::More tests => 3;
use Test::HTTP::Server;

my $server = Test::HTTP::Server->new;
ok( $server, 'server started' );
like( $server->uri, qr#^http://127\.0\.0\.1:\d+/$#, 'correct address' );

$server->address( "localhost" );
like( $server->uri, qr#^http://localhost:\d+/$#, 'address updated' );
